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
static const void *NeoWCMessageTimeIdentityKey = &NeoWCMessageTimeIdentityKey;

static NSMutableDictionary<NSString *, NSHashTable<UIView *> *> *NeoWCMessageTimeVisibleCells(void) {
    static NSMutableDictionary *cells;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ cells = [NSMutableDictionary dictionary]; });
    return cells;
}

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

static NSString *NeoWCMessageTimeIdentity(id message) {
    if (!message) return nil;
    SEL combinedSelector = NSSelectorFromString(@"combineChatNameWithLocalId");
    if ([message respondsToSelector:combinedSelector]) {
        id combined = ((id (*)(id, SEL))objc_msgSend)(message, combinedSelector);
        if ([combined isKindOfClass:NSString.class] && [combined length] > 0) {
            return [@"combined:" stringByAppendingString:combined];
        }
    }

    id localValue = NeoWCMessageTimeValue(message, @"m_uiMesLocalID");
    unsigned long long localID = [localValue respondsToSelector:@selector(unsignedLongLongValue)]
        ? [localValue unsignedLongLongValue] : 0;
    id serverValue = NeoWCMessageTimeValue(message, @"m_n64MesSvrID");
    long long serverID = [serverValue respondsToSelector:@selector(longLongValue)]
        ? [serverValue longLongValue] : 0;
    NSString *chatName = nil;
    SEL chatSelector = NSSelectorFromString(@"GetChatName");
    if ([message respondsToSelector:chatSelector]) {
        id value = ((id (*)(id, SEL))objc_msgSend)(message, chatSelector);
        if ([value isKindOfClass:NSString.class]) chatName = value;
    }
    if (chatName.length > 0 && localID > 0) {
        return [NSString stringWithFormat:@"local:%@:%llu", chatName, localID];
    }
    if (chatName.length > 0 && serverID != 0) {
        return [NSString stringWithFormat:@"server:%@:%lld", chatName, serverID];
    }
    return [NSString stringWithFormat:@"object:%p", message];
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

static BOOL NeoWCMessageTimeAnchorIsUsable(id value) {
    if (![value isKindOfClass:UIView.class]) return NO;
    UIView *view = value;
    return !view.hidden && view.alpha > 0.01 && CGRectGetWidth(view.bounds) > 1.0 && CGRectGetHeight(view.bounds) > 1.0;
}

UIView *NeoWCMessageSideAnchorView(UIView *cell) {
    if (!cell) return nil;
    SEL selector = NSSelectorFromString(@"getBgImageView");
    if ([cell respondsToSelector:selector]) {
        id value = ((id (*)(id, SEL))objc_msgSend)(cell, selector);
        if (NeoWCMessageTimeAnchorIsUsable(value)) return value;
    }
    id content = NeoWCMessageTimeFirstValue(cell, @[@"m_contentView", @"contentView", @"m_msgContentView",
                                                    @"msgContentView", @"m_messageView", @"messageView",
                                                    @"m_nodeView", @"nodeView"]);
    if ([content isKindOfClass:UIView.class]) {
        if ([content respondsToSelector:selector]) {
            id value = ((id (*)(id, SEL))objc_msgSend)(content, selector);
            if (NeoWCMessageTimeAnchorIsUsable(value)) return value;
        }
        id value = NeoWCMessageTimeFirstValue(content, @[@"m_bgImageView", @"bgImageView"]);
        if (NeoWCMessageTimeAnchorIsUsable(value)) return value;
        if (NeoWCMessageTimeAnchorIsUsable(content)) return content;
    }
    for (NSString *selectorName in @[@"getContentView", @"getMessageContentView", @"getMsgContentView", @"getNodeView"]) {
        SEL contentSelector = NSSelectorFromString(selectorName);
        if (![cell respondsToSelector:contentSelector]) continue;
        id value = ((id (*)(id, SEL))objc_msgSend)(cell, contentSelector);
        if (![value isKindOfClass:UIView.class]) continue;
        if (NeoWCMessageTimeAnchorIsUsable(value)) return value;
    }
    return nil;
}

static UILabel *NeoWCMessageTimeLabel(UIView *cell, const void *key) {
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

static void NeoWCSetMessageTimeLabelsHidden(UIView *cell) {
    UILabel *avatar = objc_getAssociatedObject(cell, NeoWCMessageTimeAvatarLabelKey);
    UILabel *bubble = objc_getAssociatedObject(cell, NeoWCMessageTimeBubbleLabelKey);
    avatar.hidden = YES;
    bubble.hidden = YES;
}

static void NeoWCMessageTimeUnregisterCell(UIView *cell) {
    NSString *identity = objc_getAssociatedObject(cell, NeoWCMessageTimeIdentityKey);
    if (identity.length == 0) return;
    NSHashTable<UIView *> *group = NeoWCMessageTimeVisibleCells()[identity];
    [group removeObject:cell];
    NSArray<UIView *> *remaining = group.allObjects;
    if (remaining.count == 0) {
        [NeoWCMessageTimeVisibleCells() removeObjectForKey:identity];
    } else if (NeoWCEnhancementEnabled(NeoWCChatMessageTimeEnabledKey)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (UIView *candidate in remaining) NeoWCScheduleMessageTimeRefresh(candidate);
        });
    }
    objc_setAssociatedObject(cell, NeoWCMessageTimeIdentityKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

void NeoWCHideMessageTimeLabels(UIView *cell) {
    NeoWCSetMessageTimeLabelsHidden(cell);
    NeoWCMessageTimeUnregisterCell(cell);
}

static NSArray<UIView *> *NeoWCMessageTimeRegisterCell(UIView *cell, NSString *identity) {
    NSString *previousIdentity = objc_getAssociatedObject(cell, NeoWCMessageTimeIdentityKey);
    if (previousIdentity.length > 0 && ![previousIdentity isEqualToString:identity]) {
        NeoWCMessageTimeUnregisterCell(cell);
    }
    NSHashTable<UIView *> *group = NeoWCMessageTimeVisibleCells()[identity];
    if (!group) {
        group = [NSHashTable weakObjectsHashTable];
        NeoWCMessageTimeVisibleCells()[identity] = group;
    }
    [group addObject:cell];
    objc_setAssociatedObject(cell, NeoWCMessageTimeIdentityKey, identity, OBJC_ASSOCIATION_COPY_NONATOMIC);
    NSMutableArray<UIView *> *visible = [NSMutableArray array];
    for (UIView *candidate in group.allObjects) {
        if (candidate.window && candidate.window == cell.window &&
            [objc_getAssociatedObject(candidate, NeoWCMessageTimeIdentityKey) isEqualToString:identity]) {
            [visible addObject:candidate];
        }
    }
    return visible;
}

static UIView *NeoWCMessageTimeOwner(NSArray<UIView *> *cells, BOOL bubbleSide) {
    UIView *owner = nil;
    BOOL ownerHasAnchor = NO;
    CGFloat ownerArea = -1.0;
    CGFloat ownerY = CGFLOAT_MAX;
    for (UIView *candidate in cells) {
        UIWindow *window = candidate.window;
        if (!window) continue;
        CGRect frame = [candidate convertRect:candidate.bounds toView:window];
        CGRect visibleFrame = CGRectIntersection(frame, window.bounds);
        CGFloat area = CGRectIsNull(visibleFrame) ? 0.0 : CGRectGetWidth(visibleFrame) * CGRectGetHeight(visibleFrame);
        if (area <= 1.0) continue;
        BOOL hasAnchor = bubbleSide ? NeoWCMessageSideAnchorView(candidate) != nil
                                    : NeoWCMessageTimeAvatarView(candidate) != nil;
        CGFloat y = CGRectGetMinY(visibleFrame);
        BOOL better = !owner ||
                      (hasAnchor && !ownerHasAnchor) ||
                      (hasAnchor == ownerHasAnchor && area > ownerArea + 1.0) ||
                      (hasAnchor == ownerHasAnchor && fabs(area - ownerArea) <= 1.0 && y < ownerY);
        if (better) {
            owner = candidate;
            ownerHasAnchor = hasAnchor;
            ownerArea = area;
            ownerY = y;
        }
    }
    return owner;
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
    // neither is set, fall back to the default below-avatar mode.
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

    NSString *identity = NeoWCMessageTimeIdentity(message);
    if (identity.length == 0) {
        NeoWCHideMessageTimeLabels(cell);
        return;
    }
    NSArray<UIView *> *messageCells = NeoWCMessageTimeRegisterCell(cell, identity);
    UIView *owner = NeoWCMessageTimeOwner(messageCells, bubbleSide);
    for (UIView *candidate in messageCells) {
        if (candidate != owner) NeoWCSetMessageTimeLabelsHidden(candidate);
    }
    if (owner != cell) {
        NeoWCSetMessageTimeLabelsHidden(cell);
        return;
    }

    NSString *format = [defaults stringForKey:NeoWCChatMessageTimeFormatKey];
    if (format.length == 0) format = @"MM-dd HH:mm:ss";
    NSString *text = NeoWCMessageTimeText(time, format);
    CGFloat configuredSize = [defaults doubleForKey:NeoWCChatMessageTimeFontSizeKey];
    CGFloat fontSize = MIN(18.0, MAX(8.0, configuredSize > 0 ? configuredSize : 10.0));
    UIFontWeight fontWeight = [defaults boolForKey:NeoWCChatMessageTimeBoldKey] ? UIFontWeightSemibold : UIFontWeightRegular;
    UIFont *font = [UIFont systemFontOfSize:fontSize weight:fontWeight];
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
            CGFloat avatarSpacing = MIN(8.0, MAX(-6.0, [defaults doubleForKey:NeoWCChatMessageTimeAvatarSpacingKey]));
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

    UILabel *bubbleLabel = objc_getAssociatedObject(cell, NeoWCMessageTimeBubbleLabelKey);
    if (bubbleSide) {
        UIView *bubble = NeoWCMessageSideAnchorView(cell);
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
            NeoWCRefreshMessageTimeLabels(delayedCell);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.18 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                UIView *finalCell = weakCell;
                if (!finalCell) return;
                objc_setAssociatedObject(finalCell, NeoWCMessageTimeRefreshPendingKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                NeoWCRefreshMessageTimeLabels(finalCell);
            });
        });
    });
}
