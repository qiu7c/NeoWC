#import "WCAtlasMessageTime.h"
#import "WCAtlasCompatibility.h"
#import "WCAtlasEnhancements.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import <math.h>

static const void *WCAtlasMessageTimeAvatarLabelKey = &WCAtlasMessageTimeAvatarLabelKey;
static const void *WCAtlasMessageTimeBubbleLabelKey = &WCAtlasMessageTimeBubbleLabelKey;
static const void *WCAtlasMessageTimeRefreshPendingKey = &WCAtlasMessageTimeRefreshPendingKey;
static const void *WCAtlasMessageTimeRefreshGenerationKey = &WCAtlasMessageTimeRefreshGenerationKey;

static id WCAtlasMessageTimeValue(id object, NSString *key) {
    if (!object || key.length == 0) return nil;
    @try {
        return [object valueForKey:key];
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static id WCAtlasMessageTimeFirstValue(id object, NSArray<NSString *> *keys) {
    for (NSString *key in keys) {
        id value = WCAtlasMessageTimeValue(object, key);
        if (value) return value;
    }
    return nil;
}

static id WCAtlasMessageTimeViewModel(UIView *cell) {
    return WCAtlasMessageTimeFirstValue(cell, @[@"viewModel", @"m_viewModel"]);
}

static id WCAtlasMessageTimeMessage(id viewModel) {
    id message = WCAtlasMessageTimeFirstValue(viewModel, @[@"messageWrap", @"m_messageWrap", @"msgWrap", @"wrap"]);
    if (message) return message;
    id parent = WCAtlasMessageTimeValue(viewModel, @"parentModel");
    return WCAtlasMessageTimeFirstValue(parent, @[@"messageWrap", @"m_messageWrap", @"msgWrap", @"wrap"]);
}

static NSTimeInterval WCAtlasMessageTimeCreateTime(id message, id viewModel) {
    for (id object in @[message ?: NSNull.null, viewModel ?: NSNull.null]) {
        if (object == NSNull.null) continue;
        id value = WCAtlasMessageTimeFirstValue(object, @[@"m_uiCreateTime", @"createTime"]);
        NSTimeInterval time = [value respondsToSelector:@selector(doubleValue)] ? [value doubleValue] : 0;
        if (isfinite(time) && time > 0) return time;
    }
    return 0;
}

static UIView *WCAtlasMessageTimeDescendant(UIView *root, BOOL (^matches)(UIView *view)) {
    if (!root || !matches) return nil;
    for (UIView *subview in root.subviews) {
        if (matches(subview)) return subview;
        UIView *nested = WCAtlasMessageTimeDescendant(subview, matches);
        if (nested) return nested;
    }
    return nil;
}

static UIView *WCAtlasMessageTimeAvatarView(UIView *cell) {
    SEL selector = NSSelectorFromString(@"getHeadImageView");
    if ([cell respondsToSelector:selector]) {
        id value = ((id (*)(id, SEL))objc_msgSend)(cell, selector);
        if ([value isKindOfClass:UIView.class] && ![value isHidden]) return value;
    }
    UIView *avatar = WCAtlasMessageTimeDescendant(cell, ^BOOL(UIView *candidate) {
        return [NSStringFromClass(candidate.class) containsString:@"MMHeadImageView"];
    });
    return avatar.hidden ? nil : avatar;
}

static BOOL WCAtlasMessageTimeAnchorIsUsable(id value) {
    if (![value isKindOfClass:UIView.class]) return NO;
    UIView *view = value;
    return !view.hidden && view.alpha > 0.01 && CGRectGetWidth(view.bounds) > 1.0 && CGRectGetHeight(view.bounds) > 1.0;
}

UIView *WCAtlasMessageSideAnchorView(UIView *cell) {
    if (!cell) return nil;
    SEL selector = NSSelectorFromString(@"getBgImageView");
    if ([cell respondsToSelector:selector]) {
        id value = ((id (*)(id, SEL))objc_msgSend)(cell, selector);
        if (WCAtlasMessageTimeAnchorIsUsable(value)) return value;
    }
    id content = WCAtlasMessageTimeFirstValue(cell, @[@"m_contentView", @"contentView", @"m_msgContentView",
                                                    @"msgContentView", @"m_messageView", @"messageView",
                                                    @"m_nodeView", @"nodeView"]);
    if ([content isKindOfClass:UIView.class]) {
        if ([content respondsToSelector:selector]) {
            id value = ((id (*)(id, SEL))objc_msgSend)(content, selector);
            if (WCAtlasMessageTimeAnchorIsUsable(value)) return value;
        }
        id value = WCAtlasMessageTimeFirstValue(content, @[@"m_bgImageView", @"bgImageView"]);
        if (WCAtlasMessageTimeAnchorIsUsable(value)) return value;
        if (WCAtlasMessageTimeAnchorIsUsable(content)) return content;
    }
    for (NSString *selectorName in @[@"getContentView", @"getMessageContentView", @"getMsgContentView", @"getNodeView"]) {
        SEL contentSelector = NSSelectorFromString(selectorName);
        if (![cell respondsToSelector:contentSelector]) continue;
        id value = ((id (*)(id, SEL))objc_msgSend)(cell, contentSelector);
        if (![value isKindOfClass:UIView.class]) continue;
        if (WCAtlasMessageTimeAnchorIsUsable(value)) return value;
    }
    return nil;
}

static UILabel *WCAtlasMessageTimeLabel(UIView *cell, const void *key) {
    UILabel *label = objc_getAssociatedObject(cell, key);
    if (label) {
        if (label.superview != cell) [cell addSubview:label];
        return label;
    }
    label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.numberOfLines = 1;
    label.textAlignment = NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.72;
    label.userInteractionEnabled = NO;
    label.layer.zPosition = 900.0;
    [cell addSubview:label];
    objc_setAssociatedObject(cell, key, label, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return label;
}

static void WCAtlasSetMessageTimeLabelsHidden(UIView *cell) {
    UILabel *avatar = objc_getAssociatedObject(cell, WCAtlasMessageTimeAvatarLabelKey);
    UILabel *bubble = objc_getAssociatedObject(cell, WCAtlasMessageTimeBubbleLabelKey);
    avatar.hidden = YES;
    bubble.hidden = YES;
}

void WCAtlasHideMessageTimeLabels(UIView *cell) {
    WCAtlasSetMessageTimeLabelsHidden(cell);
    NSUInteger generation = [objc_getAssociatedObject(cell, WCAtlasMessageTimeRefreshGenerationKey) unsignedIntegerValue];
    objc_setAssociatedObject(cell, WCAtlasMessageTimeRefreshGenerationKey,
                             @(generation + 1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(cell, WCAtlasMessageTimeRefreshPendingKey,
                             nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static NSString *WCAtlasMessageTimeText(NSTimeInterval time, NSString *format) {
    static NSCache<NSString *, NSDateFormatter *> *formatters;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ formatters = [NSCache new]; });
    NSDateFormatter *formatter = [formatters objectForKey:format];
    if (!formatter) {
        formatter = [NSDateFormatter new];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
        formatter.dateFormat = format;
        [formatters setObject:formatter forKey:format];
    }
    return [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:time]];
}

static void WCAtlasRefreshMessageTimeLabels(UIView *cell) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    BOOL enabled = WCAtlasEnhancementEnabled(WCAtlasChatMessageTimeEnabledKey);
    BOOL bubbleSide = [defaults boolForKey:WCAtlasChatMessageTimeBubbleSideKey];
    // Bubble mode wins if legacy settings ever contain both booleans. When
    // neither is set, fall back to the default below-avatar mode.
    BOOL belowAvatar = !bubbleSide;
    if (!enabled || !cell.window) {
        WCAtlasHideMessageTimeLabels(cell);
        return;
    }

    id viewModel = WCAtlasMessageTimeViewModel(cell);
    if (!viewModel) {
        WCAtlasHideMessageTimeLabels(cell);
        return;
    }
    id message = WCAtlasMessageTimeMessage(viewModel);
    NSTimeInterval time = WCAtlasMessageTimeCreateTime(message, viewModel);
    if (time <= 0) {
        WCAtlasHideMessageTimeLabels(cell);
        return;
    }

    NSString *format = [defaults stringForKey:WCAtlasChatMessageTimeFormatKey];
    if (format.length == 0) format = @"MM-dd HH:mm:ss";
    NSString *text = WCAtlasMessageTimeText(time, format);
    CGFloat configuredSize = [defaults doubleForKey:WCAtlasChatMessageTimeFontSizeKey];
    CGFloat fontSize = MIN(18.0, MAX(8.0, configuredSize > 0 ? configuredSize : 10.0));
    UIFontWeight fontWeight = [defaults boolForKey:WCAtlasChatMessageTimeBoldKey] ? UIFontWeightSemibold : UIFontWeightRegular;
    UIFont *font = [UIFont systemFontOfSize:fontSize weight:fontWeight];
    UIColor *color = WCAtlasDynamicColorForDefaultsKeys(WCAtlasChatMessageTimeLightColorKey,
                                                       WCAtlasChatMessageTimeDarkColorKey,
                                                       WCAtlasChatMessageTimeColorKey,
                                                       [UIColor colorWithRed:0.56 green:0.56 blue:0.58 alpha:1.0],
                                                       [UIColor colorWithRed:0.60 green:0.60 blue:0.62 alpha:1.0]);
    CGFloat labelHeight = MAX(12.0, ceil(fontSize * 1.5));
    CGFloat measuredWidth = ceil([text sizeWithAttributes:@{NSFontAttributeName: font}].width) + 4.0;
    CGFloat labelWidth = MIN(118.0, MAX(50.0, measuredWidth));
    BOOL isSender = [WCAtlasMessageTimeValue(viewModel, @"isSender") boolValue];

    UILabel *avatarLabel = objc_getAssociatedObject(cell, WCAtlasMessageTimeAvatarLabelKey);
    if (belowAvatar) {
        UIView *avatar = WCAtlasMessageTimeAvatarView(cell);
        if (avatar) {
            avatarLabel = WCAtlasMessageTimeLabel(cell, WCAtlasMessageTimeAvatarLabelKey);
            CGRect frame = [avatar convertRect:avatar.bounds toView:cell];
            avatarLabel.text = text;
            avatarLabel.font = font;
            avatarLabel.textColor = color;
            CGFloat avatarSpacing = MIN(8.0, MAX(-6.0, [defaults doubleForKey:WCAtlasChatMessageTimeAvatarSpacingKey]));
            avatarLabel.frame = CGRectMake(CGRectGetMidX(frame) - labelWidth * 0.5,
                                           CGRectGetMaxY(frame) + avatarSpacing,
                                           labelWidth,
                                           labelHeight);
            avatarLabel.hidden = NO;
        } else {
            avatarLabel.hidden = YES;
        }
    } else {
        avatarLabel.hidden = YES;
    }

    UILabel *bubbleLabel = objc_getAssociatedObject(cell, WCAtlasMessageTimeBubbleLabelKey);
    if (bubbleSide) {
        UIView *bubble = WCAtlasMessageSideAnchorView(cell);
        if (bubble) {
            CGRect frame = [bubble convertRect:bubble.bounds toView:cell];
            CGFloat gap = 5.0;
            CGFloat cellWidth = CGRectGetWidth(cell.bounds);
            CGFloat availableWidth = isSender ? CGRectGetMinX(frame) - gap - 2.0
                                              : cellWidth - CGRectGetMaxX(frame) - gap - 2.0;
            if (availableWidth >= 40.0) {
                CGFloat fittedWidth = MIN(labelWidth, availableWidth);
                CGFloat x = isSender ? CGRectGetMinX(frame) - fittedWidth - gap : CGRectGetMaxX(frame) + gap;
                bubbleLabel = WCAtlasMessageTimeLabel(cell, WCAtlasMessageTimeBubbleLabelKey);
                bubbleLabel.text = text;
                bubbleLabel.font = font;
                bubbleLabel.textColor = color;
                NSInteger verticalPosition = MIN(2, MAX(0, [defaults integerForKey:WCAtlasChatMessageTimeBubbleVerticalPositionKey]));
                CGFloat y = CGRectGetMinY(frame);
                if (verticalPosition == 1) y = CGRectGetMidY(frame) - labelHeight * 0.5;
                else if (verticalPosition == 2) y = CGRectGetMaxY(frame) - labelHeight;
                y = MIN(MAX(0.0, y), MAX(0.0, CGRectGetHeight(cell.bounds) - labelHeight));
                bubbleLabel.frame = CGRectMake(x,
                                               y,
                                               fittedWidth,
                                               labelHeight);
                bubbleLabel.hidden = NO;
            } else {
                bubbleLabel.hidden = YES;
            }
        } else {
            bubbleLabel.hidden = YES;
        }
    } else {
        bubbleLabel.hidden = YES;
    }
    WCAtlasCompatibilityMarkTriggered(@"chat-message-time");
}

void WCAtlasLayoutMessageTimeLabels(UIView *cell) {
    if (!cell || !cell.window ||
        !WCAtlasEnhancementEnabled(WCAtlasChatMessageTimeEnabledKey)) return;
    [UIView performWithoutAnimation:^{
        WCAtlasRefreshMessageTimeLabels(cell);
    }];
}

void WCAtlasScheduleMessageTimeRefresh(UIView *cell) {
    if (!cell) return;
    if (!WCAtlasEnhancementEnabled(WCAtlasChatMessageTimeEnabledKey)) {
        WCAtlasHideMessageTimeLabels(cell);
        return;
    }
    if ([objc_getAssociatedObject(cell, WCAtlasMessageTimeRefreshPendingKey) boolValue]) return;
    objc_setAssociatedObject(cell, WCAtlasMessageTimeRefreshPendingKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSUInteger generation = [objc_getAssociatedObject(cell, WCAtlasMessageTimeRefreshGenerationKey) unsignedIntegerValue];
    __weak UIView *weakCell = cell;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *strongCell = weakCell;
        if (!strongCell ||
            [objc_getAssociatedObject(strongCell, WCAtlasMessageTimeRefreshGenerationKey) unsignedIntegerValue] != generation) return;
        WCAtlasRefreshMessageTimeLabels(strongCell);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.08 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIView *delayedCell = weakCell;
            if (!delayedCell ||
                [objc_getAssociatedObject(delayedCell, WCAtlasMessageTimeRefreshGenerationKey) unsignedIntegerValue] != generation) return;
            WCAtlasRefreshMessageTimeLabels(delayedCell);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.18 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                UIView *finalCell = weakCell;
                if (!finalCell ||
                    [objc_getAssociatedObject(finalCell, WCAtlasMessageTimeRefreshGenerationKey) unsignedIntegerValue] != generation) return;
                objc_setAssociatedObject(finalCell, WCAtlasMessageTimeRefreshPendingKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                WCAtlasRefreshMessageTimeLabels(finalCell);
            });
        });
    });
}
