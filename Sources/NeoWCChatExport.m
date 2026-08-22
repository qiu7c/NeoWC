#import "NeoWCChatExport.h"

#import <objc/message.h>

#import "NeoWCAccount.h"
#import "NeoWCEnhancements.h"
#import "NeoWCQuickReplyStore.h"

static NSString *const NeoWCExportTextAction = @"com.qiu7c.neowc.chat-export.text";
static NSString *const NeoWCSaveImagesAction = @"com.qiu7c.neowc.chat-export.images";
static NSString *const NeoWCShareCardAction = @"com.qiu7c.neowc.chat-export.card";
static NSString *const NeoWCQuickReplyImportAction = @"com.qiu7c.neowc.quick-reply.import";
static void NeoWCShowExportMessage(UIViewController *controller, NSString *title, NSString *message);

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

static NSString *NeoWCExportConversationUsername(UIViewController *controller) {
    id contact = NeoWCExportCall(controller, @"getContact");
    if (!contact) contact = NeoWCExportCall(controller, @"GetContact");
    if (!contact) contact = NeoWCExportCall(controller, @"GetCContact");
    if (!contact) contact = NeoWCExportSafeValue(controller, @"m_contact");
    id value = NeoWCExportSafeValue(contact, @"m_nsUsrName");
    if (![value isKindOfClass:NSString.class] || [value length] == 0) {
        value = NeoWCExportSafeValue(controller, @"m_nsUsrName");
    }
    return [value isKindOfClass:NSString.class] ? value : nil;
}

static BOOL NeoWCExportOptionEnabled(NSString *key) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id value = [defaults objectForKey:key];
    return value ? [value boolValue] : YES;
}

NSArray<NSDictionary *> *NeoWCChatMultiSelectActions(UIViewController *controller) {
    NSMutableArray<NSDictionary *> *actions = [NSMutableArray array];
    if (NeoWCEnhancementEnabled(NeoWCMultiSelectExportEnabledKey)) {
        if (NeoWCExportOptionEnabled(NeoWCMultiSelectExportTextKey)) {
            [actions addObject:@{ @"id": NeoWCExportTextAction, @"title": @"纯文本", @"symbol": @"doc.on.clipboard" }];
        }
        if (NeoWCExportOptionEnabled(NeoWCMultiSelectSaveImagesKey)) {
            [actions addObject:@{ @"id": NeoWCSaveImagesAction, @"title": @"保存图片", @"symbol": @"square.and.arrow.down" }];
        }
        if (NeoWCExportOptionEnabled(NeoWCMultiSelectShareCardKey)) {
            [actions addObject:@{ @"id": NeoWCShareCardAction, @"title": @"分享卡片", @"symbol": @"rectangle.on.rectangle" }];
        }
    }
    if (NeoWCEnhancementEnabled(NeoWCQuickReplyEnabledKey) &&
        [[NeoWCExportConversationUsername(controller) lowercaseString] isEqualToString:@"filehelper"]) {
        [actions addObject:@{ @"id": NeoWCQuickReplyImportAction, @"title": @"存入素材", @"symbol": @"tray.and.arrow.down.fill" }];
    }
    return actions;
}

static BOOL NeoWCExportMessageIsFile(id wrap) {
    SEL selector = NSSelectorFromString(@"IsFileMsg");
    if ([wrap respondsToSelector:selector] && ((BOOL (*)(id, SEL))objc_msgSend)(wrap, selector)) return YES;
    return [NeoWCExportSafeValue(wrap, @"m_uiMessageType") integerValue] == 0x31 &&
           [NeoWCExportSafeValue(wrap, @"m_uiAppMsgInnerType") integerValue] == 6;
}

static NSString *NeoWCExportSourceMessageID(id wrap) {
    long long serverID = [NeoWCExportSafeValue(wrap, @"m_n64MesSvrID") longLongValue];
    unsigned long long localID = [NeoWCExportSafeValue(wrap, @"m_uiMesLocalID") unsignedLongLongValue];
    return serverID != 0 ? [NSString stringWithFormat:@"svr:%lld", serverID]
                         : [NSString stringWithFormat:@"local:%llu", localID];
}

static NSString *NeoWCExportExistingImagePath(id wrap) {
    Class wrapClass = NSClassFromString(@"CMessageWrap");
    for (NSString *selectorName in @[@"getJpgPathOfMsgHDImg:", @"getJpgPathOfMsgHdOrMiddleImg:",
                                      @"getJpgPathOfMsgMiddleImg:", @"getPathOfMsgImg:"]) {
        SEL selector = NSSelectorFromString(selectorName);
        if (![wrapClass respondsToSelector:selector]) continue;
        id value = ((id (*)(id, SEL, id))objc_msgSend)(wrapClass, selector, wrap);
        NSString *path = [value isKindOfClass:NSString.class] ? value : nil;
        if (path.length > 0 && [NSFileManager.defaultManager fileExistsAtPath:path]) return path;
    }
    return nil;
}

static NSString *NeoWCExportExistingAttachmentPath(id wrap) {
    SEL selector = NSSelectorFromString(@"GetAppAttachmentPath");
    if (![wrap respondsToSelector:selector]) return nil;
    id value = ((id (*)(id, SEL))objc_msgSend)(wrap, selector);
    NSString *path = [value isKindOfClass:NSString.class] ? value : nil;
    return path.length > 0 && [NSFileManager.defaultManager fileExistsAtPath:path] ? path : nil;
}

static NSString *NeoWCExportExistingVoicePath(id wrap) {
    SEL selector = NSSelectorFromString(@"getVoicePath");
    if (![wrap respondsToSelector:selector]) return nil;
    id value = ((id (*)(id, SEL))objc_msgSend)(wrap, selector);
    NSString *path = [value isKindOfClass:NSString.class] ? value : nil;
    return path.length > 0 && [NSFileManager.defaultManager fileExistsAtPath:path] ? path : nil;
}

static NSDictionary *NeoWCExportVoiceMetadata(id wrap) {
    id extendInfo = NeoWCExportSafeValue(wrap, @"m_extendInfoWithMsgType");
    NSNumber *voiceTime = NeoWCExportSafeValue(extendInfo, @"m_uiVoiceTime");
    NSNumber *voiceFormat = NeoWCExportSafeValue(extendInfo, @"m_uiVoiceFormat");
    NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
    if ([voiceTime respondsToSelector:@selector(unsignedIntegerValue)] && voiceTime.unsignedIntegerValue > 0) metadata[@"voiceTime"] = voiceTime;
    if ([voiceFormat respondsToSelector:@selector(unsignedIntegerValue)]) metadata[@"voiceFormat"] = voiceFormat;
    return metadata;
}

static void NeoWCImportSelectedQuickRepliesWithMetadata(UIViewController *controller, NSArray *messages,
                                                        NSString *remark, NSString *folderIdentifier) {
    NSString *trimmedRemark = [remark stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSUInteger imported = 0, alreadyPresent = 0, unavailable = 0, unsupported = 0;
    for (id wrap in messages) {
        NSInteger type = [NeoWCExportSafeValue(wrap, @"m_uiMessageType") integerValue];
        NSString *sourceID = NeoWCExportSourceMessageID(wrap);
        NSUInteger beforeCount = NeoWCQuickReplyStore.sharedStore.items.count;
        NSError *error = nil;
        NeoWCQuickReplyItem *item = nil;
        if (type == 1) {
            NSString *text = NeoWCExportSafeValue(wrap, @"m_nsContent");
            item = [NeoWCQuickReplyStore.sharedStore addText:text ?: @"" title:trimmedRemark folderIdentifier:folderIdentifier
                                         sourceConversation:@"filehelper" sourceMessageID:sourceID error:&error];
        } else if (type == 3) {
            NSString *path = NeoWCExportExistingImagePath(wrap);
            if (path.length == 0) { unavailable++; continue; }
            item = [NeoWCQuickReplyStore.sharedStore addMediaAtURL:[NSURL fileURLWithPath:path]
                                                               type:NeoWCQuickReplyTypeImage title:trimmedRemark
                                                   folderIdentifier:folderIdentifier
                                                  sourceConversation:@"filehelper" sourceMessageID:sourceID error:&error];
        } else if (type == 34) {
            NSString *path = NeoWCExportExistingVoicePath(wrap);
            if (path.length == 0) { unavailable++; continue; }
            item = [NeoWCQuickReplyStore.sharedStore addMediaAtURL:[NSURL fileURLWithPath:path]
                                                               type:NeoWCQuickReplyTypeVoice title:trimmedRemark
                                                   folderIdentifier:folderIdentifier
                                                  sourceConversation:@"filehelper" sourceMessageID:sourceID error:&error];
            if (item && NeoWCQuickReplyStore.sharedStore.items.count > beforeCount) {
                item.metadata = NeoWCExportVoiceMetadata(wrap);
                [NeoWCQuickReplyStore.sharedStore updateItem:item error:&error];
            }
        } else if (NeoWCExportMessageIsFile(wrap)) {
            NSString *fileName = NeoWCExportSafeValue(wrap, @"m_nsAppFileName");
            NSSet *extensions = [NSSet setWithArray:@[@"mp4", @"mov", @"m4v"]];
            if (![extensions containsObject:fileName.pathExtension.lowercaseString]) { unsupported++; continue; }
            NSString *path = NeoWCExportExistingAttachmentPath(wrap);
            if (path.length == 0) { unavailable++; continue; }
            item = [NeoWCQuickReplyStore.sharedStore addMediaAtURL:[NSURL fileURLWithPath:path]
                                                               type:NeoWCQuickReplyTypeVideo title:trimmedRemark
                                                   folderIdentifier:folderIdentifier
                                                   sourceConversation:@"filehelper" sourceMessageID:sourceID error:&error];
        } else {
            unsupported++;
            continue;
        }
        if (item) {
            BOOL isNew = NeoWCQuickReplyStore.sharedStore.items.count > beforeCount;
            if (isNew) imported++;
            else alreadyPresent++;
        } else {
            unavailable++;
        }
    }
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if (imported) [parts addObject:[NSString stringWithFormat:@"新增 %lu 项", (unsigned long)imported]];
    if (alreadyPresent) [parts addObject:[NSString stringWithFormat:@"已存在 %lu 项", (unsigned long)alreadyPresent]];
    if (unavailable) [parts addObject:[NSString stringWithFormat:@"未下载或读取失败 %lu 项", (unsigned long)unavailable]];
    if (unsupported) [parts addObject:[NSString stringWithFormat:@"不支持 %lu 项", (unsigned long)unsupported]];
    NeoWCShowExportMessage(controller, imported > 0 ? @"已加入素材库" : @"没有新增素材",
                           parts.count > 0 ? [parts componentsJoinedByString:@"，"] : @"没有可导入的消息。");
}

static void NeoWCPresentQuickReplyImportFolderPicker(UIViewController *controller, NSArray *messages, NSString *remark) {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"存入文件夹" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    void (^importIntoFolder)(NSString *) = ^(NSString *folderIdentifier) {
        NeoWCImportSelectedQuickRepliesWithMetadata(controller, messages, remark, folderIdentifier);
    };
    [sheet addAction:[UIAlertAction actionWithTitle:@"素材库根目录" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        importIntoFolder(nil);
    }]];
    for (NeoWCQuickReplyFolder *folder in NeoWCQuickReplyStore.sharedStore.folders) {
        [sheet addAction:[UIAlertAction actionWithTitle:folder.name style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            importIntoFolder(folder.identifier);
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"新建文件夹" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"新建文件夹" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"文件夹名称"; }];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"创建并导入" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *saveAction) {
            NSError *error = nil;
            NeoWCQuickReplyFolder *folder = [NeoWCQuickReplyStore.sharedStore createFolderWithName:alert.textFields.firstObject.text error:&error];
            if (folder) importIntoFolder(folder.identifier);
            else NeoWCShowExportMessage(controller, @"无法创建文件夹", error.localizedDescription ?: @"文件夹名称无效。");
        }]];
        [controller presentViewController:alert animated:YES completion:nil];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover) { popover.sourceView = controller.view; popover.sourceRect = controller.view.bounds; }
    [controller presentViewController:sheet animated:YES completion:nil];
}

static void NeoWCPresentQuickReplyImportConfiguration(UIViewController *controller, NSArray *messages) {
    BOOL single = messages.count == 1;
    NSString *message = single ? @"可填写备注并选择保存文件夹。" :
        [NSString stringWithFormat:@"将导入 %lu 条消息并统一存入一个文件夹；每条备注可稍后在素材库右滑重命名。", (unsigned long)messages.count];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"加入快捷回复素材库"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    if (single) [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"备注（可选）"; }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"选择文件夹" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSString *remark = single ? alert.textFields.firstObject.text : @"";
        NeoWCPresentQuickReplyImportFolderPicker(controller, messages, remark ?: @"");
    }]];
    [controller presentViewController:alert animated:YES completion:nil];
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
    Class managerClass = NSClassFromString(@"CContactMgr");
    SEL contactSelector = NSSelectorFromString(@"getContactByName:");
    if (!managerClass) return nil;
    id manager = NeoWCServiceForClass(managerClass);
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
                      [identifier isEqualToString:NeoWCShareCardAction] ||
                      [identifier isEqualToString:NeoWCQuickReplyImportAction];
    if (!recognized) return NO;
    NSArray *messages = NeoWCSelectedMessages(controller);
    if (messages.count == 0) {
        NeoWCShowExportMessage(controller, @"没有选中消息", @"请先选择至少一条消息。");
        return YES;
    }
    if ([identifier isEqualToString:NeoWCQuickReplyImportAction]) {
        if (![[NeoWCExportConversationUsername(controller) lowercaseString] isEqualToString:@"filehelper"]) return YES;
        NeoWCPresentQuickReplyImportConfiguration(controller, messages);
    } else if ([identifier isEqualToString:NeoWCExportTextAction]) {
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
