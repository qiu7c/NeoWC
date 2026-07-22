#import "NeoWCChatExport.h"

#import <objc/message.h>

#import "NeoWCEnhancements.h"

static NSString *const NeoWCExportTextAction = @"com.qiu7c.neowc.chat-export.text";
static NSString *const NeoWCSaveImagesAction = @"com.qiu7c.neowc.chat-export.images";
static NSString *const NeoWCShareCardAction = @"com.qiu7c.neowc.chat-export.card";

typedef NS_ENUM(NSInteger, NeoWCShareCardStyle) {
    NeoWCShareCardStyleMinimal = 0,
    NeoWCShareCardStyleConversation = 1,
    NeoWCShareCardStyleDark = 2,
};

static id NeoWCExportSafeValue(id object, NSString *key) {
    if (!object || key.length == 0) return nil;
    @try { return [object valueForKey:key]; }
    @catch (__unused NSException *exception) { return nil; }
}

static id NeoWCExportCall(id object, NSString *selectorName) {
    SEL selector = NSSelectorFromString(selectorName);
    if (!object || ![object respondsToSelector:selector]) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(object, selector);
}

static NSArray *NeoWCSelectedMessages(UIViewController *controller) {
    id selected = NeoWCExportCall(controller, @"getSelectedMsgs");
    return [selected isKindOfClass:[NSArray class]] ? selected : @[];
}

static BOOL NeoWCExportOptionEnabled(NSString *key) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id value = [defaults objectForKey:key];
    return value ? [value boolValue] : YES;
}

NSArray<NSDictionary *> *NeoWCChatMultiSelectActions(void) {
    if (!NeoWCEnhancementEnabled(NeoWCMultiSelectExportEnabledKey)) return @[];
    NSMutableArray<NSDictionary *> *actions = [NSMutableArray array];
    if (NeoWCExportOptionEnabled(NeoWCMultiSelectExportTextKey)) {
        [actions addObject:@{ @"id": NeoWCExportTextAction, @"title": @"纯文本", @"symbol": @"doc.on.clipboard" }];
    }
    if (NeoWCExportOptionEnabled(NeoWCMultiSelectSaveImagesKey)) {
        [actions addObject:@{ @"id": NeoWCSaveImagesAction, @"title": @"保存图片", @"symbol": @"square.and.arrow.down" }];
    }
    if (NeoWCExportOptionEnabled(NeoWCMultiSelectShareCardKey)) {
        [actions addObject:@{ @"id": NeoWCShareCardAction, @"title": @"分享卡片", @"symbol": @"rectangle.on.rectangle" }];
    }
    return actions;
}

static NSString *NeoWCMessageBody(id wrap) {
    NSUInteger type = [NeoWCExportSafeValue(wrap, @"m_uiMessageType") unsignedIntegerValue];
    id contentValue = NeoWCExportSafeValue(wrap, @"m_nsContent");
    NSString *content = [contentValue isKindOfClass:[NSString class]] ? contentValue : nil;
    if (type == 1 && content.length > 0) return content;
    id titleValue = NeoWCExportSafeValue(wrap, @"m_nsTitle");
    NSString *title = [titleValue isKindOfClass:[NSString class]] ? titleValue : nil;
    if (title.length > 0) return title;
    switch (type) {
        case 3: return @"图片";
        case 34: return @"语音";
        case 43: return @"视频";
        case 47: return @"表情";
        case 48: return @"位置";
        case 49: return @"分享内容";
        default: return content.length > 0 && ![content hasPrefix:@"<"] ? content : @"消息";
    }
}

static id NeoWCContactForUsername(NSString *username) {
    if (username.length == 0) return nil;
    Class centerClass = NSClassFromString(@"MMServiceCenter");
    Class managerClass = NSClassFromString(@"CContactMgr");
    SEL defaultSelector = NSSelectorFromString(@"defaultCenter");
    SEL serviceSelector = NSSelectorFromString(@"getService:");
    SEL contactSelector = NSSelectorFromString(@"getContactByName:");
    if (!centerClass || !managerClass || ![centerClass respondsToSelector:defaultSelector]) return nil;
    id center = ((id (*)(id, SEL))objc_msgSend)(centerClass, defaultSelector);
    if (!center || ![center respondsToSelector:serviceSelector]) return nil;
    id manager = ((id (*)(id, SEL, Class))objc_msgSend)(center, serviceSelector, managerClass);
    if (!manager || ![manager respondsToSelector:contactSelector]) return nil;
    return ((id (*)(id, SEL, id))objc_msgSend)(manager, contactSelector, username);
}

static NSString *NeoWCContactDisplayName(id contact) {
    if (!contact) return nil;
    for (NSString *selectorName in @[@"getContactDisplayName", @"displayName", @"getRemarkOrNickName"]) {
        id value = NeoWCExportCall(contact, selectorName);
        if ([value isKindOfClass:[NSString class]] && [value length] > 0) return value;
    }
    for (NSString *key in @[@"m_nsRemark", @"m_nsNickName", @"m_nsAliasName"]) {
        id value = NeoWCExportSafeValue(contact, key);
        if ([value isKindOfClass:[NSString class]] && [value length] > 0) return value;
    }
    return nil;
}

static NSString *NeoWCSenderName(id wrap) {
    id displayValue = NeoWCExportSafeValue(wrap, @"m_nsDisplayName");
    if ([displayValue isKindOfClass:[NSString class]] && [displayValue length] > 0 && ![displayValue hasPrefix:@"wxid_"]) return displayValue;
    NSString *username = nil;
    for (NSString *key in @[@"m_nsRealChatUsr", @"m_nsFromUsr"]) {
        id value = NeoWCExportSafeValue(wrap, key);
        if ([value isKindOfClass:[NSString class]] && [value length] > 0 && ![value containsString:@"@chatroom"]) {
            username = value;
            break;
        }
    }
    NSString *displayName = NeoWCContactDisplayName(NeoWCContactForUsername(username));
    if (displayName.length > 0) return displayName;
    return username.length > 0 && ![username hasPrefix:@"wxid_"] ? username : @"好友";
}

static NSString *NeoWCConversationTitle(UIViewController *controller) {
    id contact = NeoWCExportCall(controller, @"getContact");
    if (!contact) contact = NeoWCExportCall(controller, @"GetContact");
    if (!contact) contact = NeoWCExportSafeValue(controller, @"m_contact");
    NSString *displayName = NeoWCContactDisplayName(contact);
    if (displayName.length > 0) return displayName;
    NSString *title = controller.navigationItem.title ?: controller.title;
    if (title.length > 0 && ![title hasPrefix:@"已选择"] && ![title containsString:@"条消息"]) return title;
    return @"聊天摘录";
}

static void NeoWCShowExportMessage(UIViewController *controller, NSString *title, NSString *message) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [controller presentViewController:alert animated:YES completion:nil];
}

static UIImage *NeoWCImageForMessage(id wrap) {
    for (NSString *selectorName in @[@"getRawHDThumbImagePath", @"getHDThumbImagePath", @"getThumbImagePath"]) {
        id path = NeoWCExportCall(wrap, selectorName);
        if ([path isKindOfClass:[NSString class]] && [path length] > 0) {
            UIImage *image = [UIImage imageWithContentsOfFile:path];
            if (image) return image;
        }
    }
    id thumb = NeoWCExportSafeValue(wrap, @"m_oImage");
    return [thumb isKindOfClass:[UIImage class]] ? thumb : nil;
}

static void NeoWCSaveSelectedImages(UIViewController *controller, NSArray *messages) {
    NSUInteger count = 0;
    for (id wrap in messages) {
        if ([NeoWCExportSafeValue(wrap, @"m_uiMessageType") unsignedIntegerValue] != 3) continue;
        UIImage *image = NeoWCImageForMessage(wrap);
        if (!image) continue;
        UIImageWriteToSavedPhotosAlbum(image, nil, NULL, NULL);
        count++;
    }
    NeoWCShowExportMessage(controller, count > 0 ? @"正在保存" : @"没有可保存的图片",
                           count > 0 ? [NSString stringWithFormat:@"已提交 %lu 张图片到系统相册。", (unsigned long)count]
                                     : @"所选消息没有已下载到本机的图片。");
}

static CGFloat NeoWCTextHeight(NSString *text, UIFont *font, CGFloat width) {
    CGRect rect = [text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                  attributes:@{ NSFontAttributeName: font }
                                     context:nil];
    return MAX(font.lineHeight, ceil(CGRectGetHeight(rect)));
}

static UIImage *NeoWCRenderShareCard(NSArray *messages, NSString *chatName, NeoWCShareCardStyle style) {
    CGFloat width = 390.0;
    CGFloat horizontal = 28.0;
    CGFloat textWidth = width - horizontal * 2.0;
    UIFont *senderFont = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
    UIFont *bodyFont = [UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular];
    NSMutableArray<NSDictionary *> *items = [NSMutableArray arrayWithCapacity:messages.count];
    CGFloat contentHeight = 88.0;
    for (id wrap in messages) {
        NSString *sender = NeoWCSenderName(wrap);
        NSString *body = NeoWCMessageBody(wrap);
        CGFloat bodyHeight = NeoWCTextHeight(body, bodyFont, textWidth - (style == NeoWCShareCardStyleConversation ? 24.0 : 0.0));
        CGFloat itemHeight = 22.0 + bodyHeight + 22.0;
        [items addObject:@{ @"sender": sender, @"body": body, @"height": @(itemHeight) }];
        contentHeight += itemHeight;
    }
    CGFloat height = MAX(180.0, contentHeight + 24.0);
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = MAX(2.0, UIScreen.mainScreen.scale);
    format.opaque = YES;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(width, height) format:format];
    return [renderer imageWithActions:^(__unused UIGraphicsImageRendererContext *context) {
        UIColor *canvas = style == NeoWCShareCardStyleDark ? [UIColor colorWithWhite:0.08 alpha:1.0] : (style == NeoWCShareCardStyleConversation ? [UIColor colorWithWhite:0.94 alpha:1.0] : UIColor.whiteColor);
        UIColor *primary = style == NeoWCShareCardStyleDark ? UIColor.whiteColor : UIColor.blackColor;
        UIColor *secondary = style == NeoWCShareCardStyleDark ? [UIColor colorWithWhite:0.68 alpha:1.0] : [UIColor colorWithWhite:0.42 alpha:1.0];
        [canvas setFill];
        UIRectFill(CGRectMake(0.0, 0.0, width, height));
        NSString *header = chatName.length > 0 ? chatName : @"聊天摘录";
        [header drawInRect:CGRectMake(horizontal, 28.0, textWidth, 34.0)
           withAttributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:22.0 weight:UIFontWeightBold], NSForegroundColorAttributeName: primary }];
        CGFloat y = 82.0;
        for (NSDictionary *item in items) {
            CGFloat itemHeight = [item[@"height"] doubleValue];
            CGRect contentRect = CGRectMake(horizontal, y, textWidth, itemHeight - 10.0);
            if (style == NeoWCShareCardStyleConversation) {
                [[UIColor whiteColor] setFill];
                [[UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:14.0] fill];
            } else if (style == NeoWCShareCardStyleMinimal) {
                [[UIColor colorWithWhite:0.90 alpha:1.0] setStroke];
                UIBezierPath *line = [UIBezierPath bezierPath];
                [line moveToPoint:CGPointMake(horizontal, CGRectGetMaxY(contentRect))];
                [line addLineToPoint:CGPointMake(width - horizontal, CGRectGetMaxY(contentRect))];
                line.lineWidth = 0.5;
                [line stroke];
            }
            CGFloat inset = style == NeoWCShareCardStyleConversation ? 12.0 : 0.0;
            [item[@"sender"] drawInRect:CGRectMake(horizontal + inset, y + 8.0, textWidth - inset * 2.0, 18.0)
                         withAttributes:@{ NSFontAttributeName: senderFont, NSForegroundColorAttributeName: secondary }];
            [item[@"body"] drawInRect:CGRectMake(horizontal + inset, y + 31.0, textWidth - inset * 2.0, itemHeight - 38.0)
                       withAttributes:@{ NSFontAttributeName: bodyFont, NSForegroundColorAttributeName: primary }];
            y += itemHeight;
        }
    }];
}

static void NeoWCPresentShareCard(UIViewController *controller, NSArray *messages, NeoWCShareCardStyle style) {
    UIImage *card = NeoWCRenderShareCard(messages, NeoWCConversationTitle(controller), style);
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[card] applicationActivities:nil];
    UIPopoverPresentationController *popover = activity.popoverPresentationController;
    if (popover) { popover.sourceView = controller.view; popover.sourceRect = controller.view.bounds; }
    [controller presentViewController:activity animated:YES completion:nil];
}

static void NeoWCPresentShareCardStylePicker(UIViewController *controller, NSArray *messages) {
    UIAlertController *picker = [UIAlertController alertControllerWithTitle:@"选择分享卡片样式" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray<NSDictionary *> *styles = @[
        @{ @"title": @"极简留白", @"value": @(NeoWCShareCardStyleMinimal) },
        @{ @"title": @"对话卡片", @"value": @(NeoWCShareCardStyleConversation) },
        @{ @"title": @"深色简报", @"value": @(NeoWCShareCardStyleDark) },
    ];
    for (NSDictionary *style in styles) {
        [picker addAction:[UIAlertAction actionWithTitle:style[@"title"] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            NeoWCPresentShareCard(controller, messages, [style[@"value"] integerValue]);
        }]];
    }
    [picker addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = picker.popoverPresentationController;
    if (popover) { popover.sourceView = controller.view; popover.sourceRect = controller.view.bounds; }
    [controller presentViewController:picker animated:YES completion:nil];
}

BOOL NeoWCHandleChatMultiSelectAction(UIViewController *controller, NSString *identifier) {
    if (!controller || identifier.length == 0) return NO;
    BOOL recognized = [identifier isEqualToString:NeoWCExportTextAction] ||
                      [identifier isEqualToString:NeoWCSaveImagesAction] ||
                      [identifier isEqualToString:NeoWCShareCardAction];
    if (!recognized) return NO;
    NSArray *messages = NeoWCSelectedMessages(controller);
    if (messages.count == 0) {
        NeoWCShowExportMessage(controller, @"没有选中消息", @"请先选择至少一条消息。");
        return YES;
    }
    if ([identifier isEqualToString:NeoWCExportTextAction]) {
        NSMutableArray<NSString *> *bodies = [NSMutableArray arrayWithCapacity:messages.count];
        for (id wrap in messages) {
            NSString *body = [NeoWCMessageBody(wrap) stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (body.length > 0) [bodies addObject:body];
        }
        UIPasteboard.generalPasteboard.string = [bodies componentsJoinedByString:@"\n"];
        NeoWCShowExportMessage(controller, @"已复制", [NSString stringWithFormat:@"%lu 条消息正文已复制到剪贴板。", (unsigned long)bodies.count]);
    } else if ([identifier isEqualToString:NeoWCSaveImagesAction]) {
        NeoWCSaveSelectedImages(controller, messages);
    } else {
        NeoWCPresentShareCardStylePicker(controller, messages);
    }
    return YES;
}
