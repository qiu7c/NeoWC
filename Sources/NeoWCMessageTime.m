#import "NeoWCMessageTime.h"
#import "NeoWCCompatibility.h"
#import "NeoWCEnhancements.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import <float.h>
#import <math.h>

static const void *NeoWCMessageTimeAvatarLabelKey = &NeoWCMessageTimeAvatarLabelKey;
static const void *NeoWCMessageTimeBubbleLabelKey = &NeoWCMessageTimeBubbleLabelKey;
static const void *NeoWCMessageTimeRefreshPendingKey = &NeoWCMessageTimeRefreshPendingKey;

static id NeoWCMessageTimeValue(id object, NSString *key) {
    if (!object || key.length == 0) return nil;
    @try {
        return [object valueForKey:key];
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static id NeoWCMessageTimeFirstValue(id object, NSArray<NSString *> *keys) {
    for (NSString *key in keys) {
        id value = NeoWCMessageTimeValue(object, key);
        if (value) return value;
    }
    return nil;
}

static id NeoWCMessageTimeViewModel(UIView *cell) {
    return NeoWCMessageTimeFirstValue(cell, @[@"viewModel", @"m_viewModel"]);
}

static id NeoWCMessageTimeMessage(id viewModel) {
    id message = NeoWCMessageTimeFirstValue(viewModel, @[@"messageWrap", @"m_messageWrap", @"msgWrap", @"wrap"]);
    if (message) return message;
    id parent = NeoWCMessageTimeValue(viewModel, @"parentModel");
    return NeoWCMessageTimeFirstValue(parent, @[@"messageWrap", @"m_messageWrap", @"msgWrap", @"wrap"]);
}

static NSTimeInterval NeoWCMessageTimeCreateTime(id message, id viewModel) {
    for (id object in @[message ?: NSNull.null, viewModel ?: NSNull.null]) {
        if (object == NSNull.null) continue;
        id value = NeoWCMessageTimeFirstValue(object, @[@"m_uiCreateTime", @"createTime"]);
        NSTimeInterval time = [value respondsToSelector:@selector(doubleValue)] ? [value doubleValue] : 0;
        if (isfinite(time) && time > 0) return time;
    }
    return 0;
}

static UIView *NeoWCMessageTimeDescendant(UIView *root, BOOL (^matches)(UIView *view)) {
    if (!root || !matches) return nil;
    for (UIView *subview in root.subviews) {
        if (matches(subview)) return subview;
        UIView *nested = NeoWCMessageTimeDescendant(subview, matches);
        if (nested) return nested;
    }
    return nil;
}

static UIView *NeoWCMessageTimeAvatarView(UIView *cell) {
    SEL selector = NSSelectorFromString(@"getHeadImageView");
    if ([cell respondsToSelector:selector]) {
        id value = ((id (*)(id, SEL))objc_msgSend)(cell, selector);
        if ([value isKindOfClass:UIView.class] && ![value isHidden]) return value;
    }
    UIView *avatar = NeoWCMessageTimeDescendant(cell, ^BOOL(UIView *candidate) {
        return [NSStringFromClass(candidate.class) containsString:@"MMHeadImageView"];
    });
    return avatar.hidden ? nil : avatar;
}

static BOOL NeoWCMessageTimeContentFrameIsUsable(CGRect frame, UIView *cell, BOOL isSender) {
    CGFloat cellWidth = CGRectGetWidth(cell.bounds);
    CGFloat cellHeight = CGRectGetHeight(cell.bounds);
    if (CGRectIsEmpty(frame) || CGRectIsNull(frame) || frame.size.width < 20.0 || frame.size.height < 16.0) return NO;
    if (frame.size.width > cellWidth * 0.9 || frame.size.height > cellHeight * 0.96) return NO;
    return isSender ? CGRectGetMidX(frame) >= cellWidth * 0.42 : CGRectGetMidX(frame) <= cellWidth * 0.58;
}

static UIView *NeoWCMessageTimeContentCandidate(UIView *root, UIView *cell, UIView *avatar, BOOL isSender, CGFloat *bestScore) {
    UIView *best = nil;
    for (UIView *subview in root.subviews) {
        if (subview.hidden || subview.alpha <= 0.01 || subview == avatar || (avatar && [subview isDescendantOfView:avatar])) continue;
        NSString *className = NSStringFromClass(subview.class);
        BOOL excludedClass = [subview isKindOfClass:UILabel.class] || [subview isKindOfClass:UIButton.class] ||
            [className containsString:@"HeadImage"] || [className containsString:@"Avatar"];
        if (!excludedClass) {
            CGRect frame = [subview convertRect:subview.bounds toView:cell];
            if (NeoWCMessageTimeContentFrameIsUsable(frame, cell, isSender)) {
                CGFloat score = frame.size.width * frame.size.height;
                if ([className containsString:@"Message"] || [className containsString:@"Content"] ||
                    [className containsString:@"Image"] || [className containsString:@"Voice"] ||
                    [className containsString:@"Emoticon"] || [className containsString:@"App"]) score += 100000.0;
                if (score > *bestScore) {
                    *bestScore = score;
                    best = subview;
                }
            }
        }
        UIView *nested = NeoWCMessageTimeContentCandidate(subview, cell, avatar, isSender, bestScore);
        if (nested) best = nested;
    }
    return best;
}

static UIView *NeoWCMessageTimeBubbleView(UIView *cell, BOOL isSender) {
    SEL selector = NSSelectorFromString(@"getBgImageView");
    if ([cell respondsToSelector:selector]) {
        id value = ((id (*)(id, SEL))objc_msgSend)(cell, selector);
        if ([value isKindOfClass:UIView.class] && ![value isHidden]) {
            CGRect frame = [(UIView *)value convertRect:[(UIView *)value bounds] toView:cell];
            if (NeoWCMessageTimeContentFrameIsUsable(frame, cell, isSender)) return value;
        }
    }
    id content = NeoWCMessageTimeFirstValue(cell, @[@"m_contentView", @"contentView"]);
    if ([content isKindOfClass:UIView.class]) {
        if ([content respondsToSelector:selector]) {
            id value = ((id (*)(id, SEL))objc_msgSend)(content, selector);
            if ([value isKindOfClass:UIView.class] && ![value isHidden]) {
                CGRect frame = [(UIView *)value convertRect:[(UIView *)value bounds] toView:cell];
                if (NeoWCMessageTimeContentFrameIsUsable(frame, cell, isSender)) return value;
            }
        }
        id value = NeoWCMessageTimeFirstValue(content, @[@"m_bgImageView", @"bgImageView"]);
        if ([value isKindOfClass:UIView.class] && ![value isHidden]) {
            CGRect frame = [(UIView *)value convertRect:[(UIView *)value bounds] toView:cell];
            if (NeoWCMessageTimeContentFrameIsUsable(frame, cell, isSender)) return value;
        }
        CGRect contentFrame = [(UIView *)content convertRect:[(UIView *)content bounds] toView:cell];
        if (NeoWCMessageTimeContentFrameIsUsable(contentFrame, cell, isSender)) return content;
    }
    for (NSString *selectorName in @[@"getContentView", @"getMessageContentView", @"getMsgContentView", @"getNodeView"]) {
        SEL contentSelector = NSSelectorFromString(selectorName);
        if (![cell respondsToSelector:contentSelector]) continue;
        id value = ((id (*)(id, SEL))objc_msgSend)(cell, contentSelector);
        if (![value isKindOfClass:UIView.class]) continue;
        CGRect frame = [(UIView *)value convertRect:[(UIView *)value bounds] toView:cell];
        if (NeoWCMessageTimeContentFrameIsUsable(frame, cell, isSender)) return value;
    }
    UIView *avatar = NeoWCMessageTimeAvatarView(cell);
    CGFloat bestScore = 0.0;
    return NeoWCMessageTimeContentCandidate(cell, cell, avatar, isSender, &bestScore);
}

static UILabel *NeoWCMessageTimeLabel(UIView *cell, const void *key) {
    UILabel *label = objc_getAssociatedObject(cell, key);
    if (label) return label;
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

void NeoWCHideMessageTimeLabels(UIView *cell) {
    UILabel *avatar = objc_getAssociatedObject(cell, NeoWCMessageTimeAvatarLabelKey);
    UILabel *bubble = objc_getAssociatedObject(cell, NeoWCMessageTimeBubbleLabelKey);
    avatar.hidden = YES;
    bubble.hidden = YES;
}

static NSString *NeoWCMessageTimeText(NSTimeInterval time, NSString *format) {
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

static void NeoWCRefreshMessageTimeLabels(UIView *cell) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    BOOL enabled = NeoWCEnhancementEnabled(NeoWCChatMessageTimeEnabledKey);
    BOOL bubbleSide = [defaults boolForKey:NeoWCChatMessageTimeBubbleSideKey];
    // Bubble mode wins if legacy settings ever contain both booleans. When
    // neither is set, fall back to the default avatar-between mode.
    BOOL belowAvatar = !bubbleSide;
    if (!enabled || !cell.window) {
        NeoWCHideMessageTimeLabels(cell);
        return;
    }

    id viewModel = NeoWCMessageTimeViewModel(cell);
    if (!viewModel) {
        NeoWCHideMessageTimeLabels(cell);
        return;
    }
    id message = NeoWCMessageTimeMessage(viewModel);
    NSTimeInterval time = NeoWCMessageTimeCreateTime(message, viewModel);
    if (time <= 0) {
        NeoWCHideMessageTimeLabels(cell);
        return;
    }

    NSString *format = [defaults stringForKey:NeoWCChatMessageTimeFormatKey];
    if (format.length == 0) format = @"MM-dd HH:mm:ss";
    NSString *text = NeoWCMessageTimeText(time, format);
    CGFloat configuredSize = [defaults doubleForKey:NeoWCChatMessageTimeFontSizeKey];
    CGFloat fontSize = MIN(18.0, MAX(8.0, configuredSize > 0 ? configuredSize : 10.0));
    UIFont *font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightRegular];
    UIColor *color = NeoWCColorForDefaultsKey(NeoWCChatMessageTimeColorKey, UIColor.secondaryLabelColor);
    CGFloat labelHeight = MAX(12.0, ceil(fontSize * 1.5));
    CGFloat measuredWidth = ceil([text sizeWithAttributes:@{NSFontAttributeName: font}].width) + 4.0;
    CGFloat labelWidth = MIN(118.0, MAX(50.0, measuredWidth));
    BOOL isSender = [NeoWCMessageTimeValue(viewModel, @"isSender") boolValue];

    UILabel *avatarLabel = objc_getAssociatedObject(cell, NeoWCMessageTimeAvatarLabelKey);
    if (belowAvatar) {
        UIView *avatar = NeoWCMessageTimeAvatarView(cell);
        if (avatar) {
            avatarLabel = NeoWCMessageTimeLabel(cell, NeoWCMessageTimeAvatarLabelKey);
            CGRect frame = [avatar convertRect:avatar.bounds toView:cell];
            avatarLabel.text = text;
            avatarLabel.font = font;
            avatarLabel.textColor = color;
            CGFloat cellBottom = MAX(CGRectGetMaxY(frame) + labelHeight + 2.0, CGRectGetHeight(cell.bounds) - 2.0);
            CGFloat centeredGapY = CGRectGetMaxY(frame) + (cellBottom - CGRectGetMaxY(frame) - labelHeight) * 0.5;
            avatarLabel.frame = CGRectMake(CGRectGetMidX(frame) - labelWidth * 0.5,
                                           MAX(CGRectGetMaxY(frame) + 1.0, centeredGapY),
                                           labelWidth,
                                           labelHeight);
            avatarLabel.hidden = NO;
        } else {
            avatarLabel.hidden = YES;
        }
    } else {
        avatarLabel.hidden = YES;
    }

    UILabel *bubbleLabel = objc_getAssociatedObject(cell, NeoWCMessageTimeBubbleLabelKey);
    if (bubbleSide) {
        UIView *bubble = NeoWCMessageTimeBubbleView(cell, isSender);
        if (bubble) {
            CGRect frame = [bubble convertRect:bubble.bounds toView:cell];
            CGFloat gap = 5.0;
            CGFloat cellWidth = CGRectGetWidth(cell.bounds);
            CGFloat availableWidth = isSender ? CGRectGetMinX(frame) - gap - 2.0
                                              : cellWidth - CGRectGetMaxX(frame) - gap - 2.0;
            if (availableWidth >= 40.0) {
                CGFloat fittedWidth = MIN(labelWidth, availableWidth);
                CGFloat x = isSender ? CGRectGetMinX(frame) - fittedWidth - gap : CGRectGetMaxX(frame) + gap;
                bubbleLabel = NeoWCMessageTimeLabel(cell, NeoWCMessageTimeBubbleLabelKey);
                bubbleLabel.text = text;
                bubbleLabel.font = font;
                bubbleLabel.textColor = color;
                NSInteger verticalPosition = MIN(2, MAX(0, [defaults integerForKey:NeoWCChatMessageTimeBubbleVerticalPositionKey]));
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
    NeoWCCompatibilityMarkTriggered(@"chat-message-time");
}

void NeoWCScheduleMessageTimeRefresh(UIView *cell) {
    if (!cell) return;
    if (!NeoWCEnhancementEnabled(NeoWCChatMessageTimeEnabledKey)) {
        NeoWCHideMessageTimeLabels(cell);
        return;
    }
    if ([objc_getAssociatedObject(cell, NeoWCMessageTimeRefreshPendingKey) boolValue]) return;
    objc_setAssociatedObject(cell, NeoWCMessageTimeRefreshPendingKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    __weak UIView *weakCell = cell;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *strongCell = weakCell;
        if (!strongCell) return;
        NeoWCRefreshMessageTimeLabels(strongCell);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.08 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIView *delayedCell = weakCell;
            if (!delayedCell) return;
            objc_setAssociatedObject(delayedCell, NeoWCMessageTimeRefreshPendingKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            NeoWCRefreshMessageTimeLabels(delayedCell);
        });
    });
}
