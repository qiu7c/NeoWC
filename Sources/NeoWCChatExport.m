#import "NeoWCChatExport.h"

#import <objc/message.h>
#import <objc/runtime.h>

static NSString *const NeoWCExportTextAction = @"com.qiu7c.neowc.chat-export.text";
static NSString *const NeoWCExportMarkdownAction = @"com.qiu7c.neowc.chat-export.markdown";
static NSString *const NeoWCSaveImagesAction = @"com.qiu7c.neowc.chat-export.images";
static NSString *const NeoWCShareCardAction = @"com.qiu7c.neowc.chat-export.card";

NSArray<NSDictionary *> *NeoWCChatMultiSelectActions(void) {
    return @[
        @{ @"id": NeoWCExportTextAction, @"title": @"纯文本", @"symbol": @"doc.plaintext" },
        @{ @"id": NeoWCExportMarkdownAction, @"title": @"Markdown", @"symbol": @"text.document" },
        @{ @"id": NeoWCSaveImagesAction, @"title": @"保存图片", @"symbol": @"square.and.arrow.down" },
        @{ @"id": NeoWCShareCardAction, @"title": @"分享卡片", @"symbol": @"rectangle.on.rectangle" },
    ];
}

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

static NSString *NeoWCMessageTypeSummary(id wrap) {
    NSUInteger type = [NeoWCExportSafeValue(wrap, @"m_uiMessageType") unsignedIntegerValue];
    NSString *content = NeoWCExportSafeValue(wrap, @"m_nsContent");
    if (type == 1 && [content isKindOfClass:[NSString class]] && content.length > 0) return content;
    switch (type) {
        case 3: return @"[图片]";
        case 34: return @"[语音]";
        case 43: return @"[视频]";
        case 47: return @"[表情]";
        case 48: return @"[位置]";
        case 49: {
            NSString *title = NeoWCExportSafeValue(wrap, @"m_nsTitle");
            return [title isKindOfClass:[NSString class]] && title.length > 0 ? [NSString stringWithFormat:@"[分享] %@", title] : @"[文件/引用/小程序]";
        }
        default: return [NSString stringWithFormat:@"[消息类型 %lu]", (unsigned long)type];
    }
}

static NSString *NeoWCSenderName(id wrap) {
    NSArray<NSString *> *keys = @[@"m_nsDisplayName", @"m_nsRealChatUsr", @"m_nsFromUsr"];
    for (NSString *key in keys) {
        id value = NeoWCExportSafeValue(wrap, key);
        if ([value isKindOfClass:[NSString class]] && [value length] > 0) return value;
    }
    return @"未知发送者";
}

static NSString *NeoWCTimeText(id wrap) {
    NSTimeInterval timestamp = [NeoWCExportSafeValue(wrap, @"m_uiCreateTime") doubleValue];
    if (timestamp <= 0.0) return @"";
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    return [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timestamp]];
}

static void NeoWCShowExportMessage(UIViewController *controller, NSString *title, NSString *message) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [controller presentViewController:alert animated:YES completion:nil];
}

static NSURL *NeoWCWriteExport(NSArray *messages, BOOL markdown) {
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    for (id wrap in messages) {
        NSString *sender = NeoWCSenderName(wrap);
        NSString *time = NeoWCTimeText(wrap);
        NSString *summary = NeoWCMessageTypeSummary(wrap);
        [lines addObject:markdown
            ? [NSString stringWithFormat:@"### %@ · %@\n\n%@\n", sender, time, summary]
            : [NSString stringWithFormat:@"[%@] %@\n%@\n", time, sender, summary]];
    }
    NSString *content = [lines componentsJoinedByString:@"\n"];
    NSString *extension = markdown ? @"md" : @"txt";
    NSString *name = [NSString stringWithFormat:@"NeoWC-聊天导出-%@.%@", @((long long)NSDate.date.timeIntervalSince1970), extension];
    NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:name]];
    NSError *error = nil;
    if (![content writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&error]) return nil;
    return url;
}

static void NeoWCPresentExportURL(UIViewController *controller, NSURL *url) {
    if (!url) { NeoWCShowExportMessage(controller, @"导出失败", @"无法创建导出文件，请稍后重试。"); return; }
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
    UIPopoverPresentationController *popover = activity.popoverPresentationController;
    if (popover) { popover.sourceView = controller.view; popover.sourceRect = controller.view.bounds; }
    [controller presentViewController:activity animated:YES completion:nil];
}

static UIImage *NeoWCImageForMessage(id wrap) {
    NSArray<NSString *> *selectors = @[@"getRawHDThumbImagePath", @"getHDThumbImagePath", @"getThumbImagePath"];
    for (NSString *selectorName in selectors) {
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
                           count > 0 ? [NSString stringWithFormat:@"已将 %lu 张本地可用图片提交到系统相册。", (unsigned long)count]
                                     : @"所选消息没有图片，或图片原图尚未下载到本机。");
}

static UIImage *NeoWCRenderShareCard(NSArray *messages, NSString *chatName) {
    NSUInteger count = MIN((NSUInteger)8, messages.count);
    CGFloat width = 390.0;
    CGFloat height = 118.0 + count * 66.0 + 44.0;
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = MAX(2.0, UIScreen.mainScreen.scale);
    format.opaque = YES;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(width, height) format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [[UIColor colorWithWhite:0.95 alpha:1.0] setFill];
        UIRectFill(CGRectMake(0.0, 0.0, width, height));
        [[UIColor whiteColor] setFill];
        UIBezierPath *card = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(16.0, 16.0, width - 32.0, height - 32.0) cornerRadius:18.0];
        [card fill];
        NSDictionary *titleAttributes = @{ NSFontAttributeName: [UIFont systemFontOfSize:20.0 weight:UIFontWeightSemibold], NSForegroundColorAttributeName: UIColor.blackColor };
        [(chatName.length > 0 ? chatName : @"聊天摘录") drawAtPoint:CGPointMake(34.0, 34.0) withAttributes:titleAttributes];
        NSDictionary *metaAttributes = @{ NSFontAttributeName: [UIFont systemFontOfSize:12.0], NSForegroundColorAttributeName: UIColor.grayColor };
        [[NSString stringWithFormat:@"%lu 条重点消息 · NeoWC", (unsigned long)messages.count] drawAtPoint:CGPointMake(34.0, 66.0) withAttributes:metaAttributes];
        CGFloat y = 104.0;
        for (NSUInteger index = 0; index < count; index++) {
            id wrap = messages[index];
            NSString *sender = NeoWCSenderName(wrap);
            NSString *summary = NeoWCMessageTypeSummary(wrap);
            if (summary.length > 34) summary = [[summary substringToIndex:34] stringByAppendingString:@"…"];
            NSDictionary *senderAttributes = @{ NSFontAttributeName: [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [UIColor colorWithWhite:0.25 alpha:1.0] };
            NSDictionary *bodyAttributes = @{ NSFontAttributeName: [UIFont systemFontOfSize:15.0], NSForegroundColorAttributeName: UIColor.blackColor };
            [sender drawAtPoint:CGPointMake(34.0, y) withAttributes:senderAttributes];
            [summary drawInRect:CGRectMake(34.0, y + 22.0, width - 68.0, 36.0) withAttributes:bodyAttributes];
            y += 66.0;
        }
        if (messages.count > count) {
            [[NSString stringWithFormat:@"另有 %lu 条消息未展开", (unsigned long)(messages.count - count)] drawAtPoint:CGPointMake(34.0, height - 48.0) withAttributes:metaAttributes];
        }
        (void)context;
    }];
}

BOOL NeoWCHandleChatMultiSelectAction(UIViewController *controller, NSString *identifier) {
    if (!controller || identifier.length == 0) return NO;
    BOOL recognized = [identifier isEqualToString:NeoWCExportTextAction] ||
                      [identifier isEqualToString:NeoWCExportMarkdownAction] ||
                      [identifier isEqualToString:NeoWCSaveImagesAction] ||
                      [identifier isEqualToString:NeoWCShareCardAction];
    if (!recognized) return NO;
    NSArray *messages = NeoWCSelectedMessages(controller);
    if (messages.count == 0) { NeoWCShowExportMessage(controller, @"没有选中消息", @"请先选择至少一条消息。"); return YES; }
    if ([identifier isEqualToString:NeoWCExportTextAction]) {
        NeoWCPresentExportURL(controller, NeoWCWriteExport(messages, NO));
    } else if ([identifier isEqualToString:NeoWCExportMarkdownAction]) {
        NeoWCPresentExportURL(controller, NeoWCWriteExport(messages, YES));
    } else if ([identifier isEqualToString:NeoWCSaveImagesAction]) {
        NeoWCSaveSelectedImages(controller, messages);
    } else {
        NSString *chatName = controller.navigationItem.title ?: controller.title;
        UIImage *card = NeoWCRenderShareCard(messages, chatName);
        UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[card] applicationActivities:nil];
        UIPopoverPresentationController *popover = activity.popoverPresentationController;
        if (popover) { popover.sourceView = controller.view; popover.sourceRect = controller.view.bounds; }
        [controller presentViewController:activity animated:YES completion:nil];
    }
    return YES;
}
