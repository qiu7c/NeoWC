#import "NeoWCMomentsReminder.h"
#import "NeoWCAccount.h"
#import "NeoWCLogging.h"
#import "NeoWCEnhancements.h"
#import <AVFoundation/AVFoundation.h>
#import <UserNotifications/UserNotifications.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <string.h>

static NSString *const NeoWCMomentsReminderSeenItemsKey = @"com.qiu7c.neowc.moments.reminder.seen-items";

static id NeoWCMomentsReminderService(const char *className) {
    Class contextClass = objc_getClass("MMContext");
    Class serviceClass = objc_getClass(className);
    SEL activeSelector = sel_registerName("activeUserContext");
    SEL serviceSelector = sel_registerName("getService:");
    if (!contextClass || !serviceClass || ![contextClass respondsToSelector:activeSelector]) return nil;
    id context = ((id (*)(id, SEL))objc_msgSend)(contextClass, activeSelector);
    if (!context || ![context respondsToSelector:serviceSelector]) return nil;
    return ((id (*)(id, SEL, Class))objc_msgSend)(context, serviceSelector, serviceClass);
}

static NSString *NeoWCMomentsReminderLocalUsername(void) {
    Class settingClass = objc_getClass("SettingUtil");
    SEL selector = sel_registerName("getLocalUsrName:");
    if (settingClass && [settingClass respondsToSelector:selector]) {
        id value = ((id (*)(id, SEL, unsigned int))objc_msgSend)(settingClass, selector, 0);
        if ([value isKindOfClass:NSString.class] && [value length] > 0) return value;
    }
    return NeoWCCurrentUserWXID();
}

static NSString *NeoWCMomentsReminderForwardTarget(void) {
    return [NSUserDefaults.standardUserDefaults integerForKey:NeoWCMomentsReminderForwardTargetKey] == 1
        ? @"filehelper" : NeoWCMomentsReminderLocalUsername();
}

static void NeoWCMomentsReminderSendText(NSString *target, NSString *content) {
    if (target.length == 0 || content.length == 0) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        Class wrapClass = objc_getClass("CMessageWrap");
        SEL initSelector = sel_registerName("initWithMsgType:");
        if (!wrapClass || ![wrapClass instancesRespondToSelector:initSelector]) return;
        id wrap = ((id (*)(id, SEL, unsigned int))objc_msgSend)([wrapClass alloc], initSelector, 1);
        if (!wrap) return;
        NSString *from = NeoWCMomentsReminderLocalUsername();
        ((void (*)(id, SEL, id))objc_msgSend)(wrap, sel_registerName("setM_nsFromUsr:"), from);
        ((void (*)(id, SEL, id))objc_msgSend)(wrap, sel_registerName("setM_nsToUsr:"), target);
        ((void (*)(id, SEL, unsigned int))objc_msgSend)(wrap, sel_registerName("setM_uiStatus:"), 4);
        ((void (*)(id, SEL, id))objc_msgSend)(wrap, sel_registerName("setM_nsContent:"), content);
        ((void (*)(id, SEL, unsigned int))objc_msgSend)(wrap, sel_registerName("setM_uiCreateTime:"),
                                                        (unsigned int)NSDate.date.timeIntervalSince1970);
        id manager = NeoWCMomentsReminderService("CMessageMgr");
        SEL addSelector = sel_registerName("AddMsg:MsgWrap:");
        if (manager && [manager respondsToSelector:addSelector]) {
            ((void (*)(id, SEL, id, id))objc_msgSend)(manager, addSelector, target, wrap);
        }
    });
}

static void NeoWCMomentsReminderSendImage(NSString *target, UIImage *image) {
    if (target.length == 0 || !image) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSData *data = UIImagePNGRepresentation(image);
        Class logicClass = objc_getClass("WeixinContentLogicController");
        id logic = logicClass ? [[logicClass alloc] init] : nil;
        SEL formSelector = sel_registerName("FormImageMsg:withImage:withData:");
        if (!logic || !data || ![logic respondsToSelector:formSelector]) return;
        id wrap = ((id (*)(id, SEL, id, id, id))objc_msgSend)(logic, formSelector, target, image, data);
        if (!wrap) return;
        SEL extendSelector = sel_registerName("m_extendInfoWithMsgType");
        id extendInfo = [wrap respondsToSelector:extendSelector]
            ? ((id (*)(id, SEL))objc_msgSend)(wrap, extendSelector) : nil;
        SEL imageSelector = sel_registerName("setImage:withData:isOriginImage:");
        if (extendInfo && [extendInfo respondsToSelector:imageSelector]) {
            ((void (*)(id, SEL, id, id, BOOL))objc_msgSend)(extendInfo, imageSelector, image, data, YES);
        }
        id manager = NeoWCMomentsReminderService("CMessageMgr");
        SEL addSelector = sel_registerName("AddMsg:MsgWrap:");
        if (manager && [manager respondsToSelector:addSelector]) {
            ((void (*)(id, SEL, id, id))objc_msgSend)(manager, addSelector, target, wrap);
        }
    });
}

static UIImage *NeoWCMomentsReminderVideoThumbnail(NSString *path) {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    CGImageRef imageRef = [generator copyCGImageAtTime:CMTimeMakeWithSeconds(0.1, 600)
                                            actualTime:NULL error:NULL];
    if (!imageRef) return nil;
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return image;
}

static void NeoWCMomentsReminderSendVideo(NSString *target, NSString *path) {
    if (target.length == 0 || path.length == 0 || ![NSFileManager.defaultManager fileExistsAtPath:path]) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *thumb = NeoWCMomentsReminderVideoThumbnail(path);
        NSString *thumbPath = nil;
        NSData *thumbData = thumb ? UIImageJPEGRepresentation(thumb, 0.85) : nil;
        if (thumbData.length > 0) {
            thumbPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
                [NSString stringWithFormat:@"neowc-moments-video-thumb-%@.jpg", NSUUID.UUID.UUIDString]];
            if (![thumbData writeToFile:thumbPath atomically:YES]) thumbPath = nil;
        }
        id videoInfo = nil;
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
        AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        float bitrate = videoTrack.estimatedDataRate;
        Class openAPIClass = objc_getClass("OpenApiMgrHelper");
        SEL highSelector = sel_registerName("genCaptureVideoInfoWithVideoData:mediaMessage:param:");
        if (bitrate >= 5000000.0f && openAPIClass && [openAPIClass respondsToSelector:highSelector]) {
            NSData *videoData = [NSData dataWithContentsOfFile:path];
            videoInfo = ((id (*)(id, SEL, id, id, id))objc_msgSend)(openAPIClass, highSelector, videoData, nil, nil);
        }
        if (!videoInfo) {
            Class infoClass = objc_getClass("CaptureVideoInfo");
            SEL infoSelector = sel_registerName("genVideoInfoWithVideoUrl:thumb:");
            if (infoClass && [infoClass respondsToSelector:infoSelector]) {
                videoInfo = ((id (*)(id, SEL, id, id))objc_msgSend)(infoClass, infoSelector,
                                                                    [NSURL fileURLWithPath:path], thumb);
            }
        }
        SEL thumbPathSelector = sel_registerName("setThumb_path:");
        if (videoInfo && thumbPath.length > 0 && [videoInfo respondsToSelector:thumbPathSelector]) {
            ((void (*)(id, SEL, id))objc_msgSend)(videoInfo, thumbPathSelector, thumbPath);
        }
        id manager = NeoWCMomentsReminderService("CMessageMgr");
        SEL addSelector = sel_registerName("AddVideoMsg:ToUsr:VideoInfo:");
        NSString *from = NeoWCMomentsReminderLocalUsername();
        if (videoInfo && from.length > 0 && manager && [manager respondsToSelector:addSelector]) {
            ((void (*)(id, SEL, id, id, id))objc_msgSend)(manager, addSelector, from, target, videoInfo);
        }
    });
}

NSArray<NSString *> *NeoWCMomentsReminderUsers(void) {
    NSMutableOrderedSet<NSString *> *users = [NSMutableOrderedSet orderedSet];
    for (id value in [NSUserDefaults.standardUserDefaults arrayForKey:NeoWCMomentsReminderUsersKey] ?: @[]) {
        if ([value isKindOfClass:NSString.class] && [value length] > 0 && ![value hasSuffix:@"@chatroom"]) {
            [users addObject:value];
        }
    }
    return users.array;
}

void NeoWCMomentsReminderSetUserSelected(NSString *username, BOOL selected) {
    if (username.length == 0 || [username hasSuffix:@"@chatroom"]) return;
    NSMutableOrderedSet<NSString *> *users = [NSMutableOrderedSet orderedSetWithArray:NeoWCMomentsReminderUsers()];
    if (selected) [users addObject:username]; else [users removeObject:username];
    [NSUserDefaults.standardUserDefaults setObject:users.array forKey:NeoWCMomentsReminderUsersKey];
    [NSNotificationCenter.defaultCenter postNotificationName:NeoWCEnhancementDidChangeNotification
                                                       object:NeoWCMomentsReminderUsersKey];
}

static id NeoWCMomentsReminderObjectValue(id object, const char *selectorName) {
    if (!object || !selectorName) return nil;
    SEL selector = sel_registerName(selectorName);
    Method method = class_getInstanceMethod([object class], selector);
    if (!method || method_getNumberOfArguments(method) != 2) return nil;
    char returnType[8] = {0};
    method_getReturnType(method, returnType, sizeof(returnType));
    if (returnType[0] != '@') return nil;
    @try { return ((id (*)(id, SEL))objc_msgSend)(object, selector); }
    @catch (__unused NSException *exception) { return nil; }
}

static uint64_t NeoWCMomentsReminderIntegerValue(id object, const char *selectorName) {
    if (!object || !selectorName) return 0;
    SEL selector = sel_registerName(selectorName);
    Method method = class_getInstanceMethod([object class], selector);
    if (!method || method_getNumberOfArguments(method) != 2) return 0;
    char returnType[8] = {0};
    method_getReturnType(method, returnType, sizeof(returnType));
    if (returnType[0] == '@') {
        id value = NeoWCMomentsReminderObjectValue(object, selectorName);
        return [value respondsToSelector:@selector(unsignedLongLongValue)] ? [value unsignedLongLongValue] : 0;
    }
    @try { return ((uint64_t (*)(id, SEL))objc_msgSend)(object, selector); }
    @catch (__unused NSException *exception) { return 0; }
}

static NSString *NeoWCMomentsReminderString(id value) {
    if ([value isKindOfClass:NSString.class]) {
        NSString *text = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        return text.length > 0 ? text : nil;
    }
    return [value respondsToSelector:@selector(stringValue)] ? [value stringValue] : nil;
}

static NSArray *NeoWCMomentsReminderMediaList(id dataItem) {
    id contentObject = NeoWCMomentsReminderObjectValue(dataItem, "contentObj");
    id mediaList = NeoWCMomentsReminderObjectValue(contentObject, "mediaList");
    return [mediaList isKindOfClass:NSArray.class] ? mediaList : @[];
}

static id NeoWCMomentsReminderFacade(void) {
    return NeoWCMomentsReminderService("WCFacade");
}

static void NeoWCMomentsReminderDownloadImage(id mediaItem, NSString *target) {
    id facade = NeoWCMomentsReminderFacade();
    if (!facade || !mediaItem || target.length == 0) return;
    id manager = nil;
    SEL primarySelector = sel_registerName("downloadImageCdnMgr");
    SEL fallbackSelector = sel_registerName("imageDownloadCdnMgrForCategory:");
    if ([facade respondsToSelector:primarySelector]) {
        manager = ((id (*)(id, SEL))objc_msgSend)(facade, primarySelector);
    } else if ([facade respondsToSelector:fallbackSelector]) {
        manager = ((id (*)(id, SEL, unsigned int))objc_msgSend)(facade, fallbackSelector, 0);
    }
    SEL downloadSelector = sel_registerName("StartDownloadImage:downloadType:needNotify:force:");
    if (!manager || ![manager respondsToSelector:downloadSelector]) return;
    ((void (*)(id, SEL, id, unsigned int, BOOL, BOOL))objc_msgSend)(manager, downloadSelector,
                                                                   mediaItem, 2, NO, YES);
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        SEL imageSelector = sel_registerName("imageOfSize:");
        UIImage *image = nil;
        for (NSUInteger attempt = 0; attempt < 180 && !image; attempt++) {
            if ([mediaItem respondsToSelector:imageSelector]) {
                id value = ((id (*)(id, SEL, unsigned int))objc_msgSend)(mediaItem, imageSelector, 2);
                if ([value isKindOfClass:UIImage.class]) image = value;
            }
            if (!image) [NSThread sleepForTimeInterval:1.0];
        }
        if (image) NeoWCMomentsReminderSendImage(target, image);
        else NeoWCLog(@"朋友圈图片下载超时");
    });
}

static void NeoWCMomentsReminderDownloadVideo(id mediaItem, NSString *target) {
    id facade = NeoWCMomentsReminderFacade();
    if (!facade || !mediaItem || target.length == 0) return;
    id manager = nil;
    SEL primarySelector = sel_registerName("videoDownloadCdnMgrForCategory:");
    SEL fallbackManagerSelector = sel_registerName("downloadCDNMgr");
    if ([facade respondsToSelector:primarySelector]) {
        manager = ((id (*)(id, SEL, unsigned int))objc_msgSend)(facade, primarySelector,
                                                                arc4random_uniform(10));
    } else if ([facade respondsToSelector:fallbackManagerSelector]) {
        manager = ((id (*)(id, SEL))objc_msgSend)(facade, fallbackManagerSelector);
    }
    SEL modeSelector = sel_registerName("StartDownloadVideo:DownloadMode:");
    SEL fallbackSelector = sel_registerName("StartDownloadVideo:");
    if ([manager respondsToSelector:modeSelector]) {
        ((void (*)(id, SEL, id, unsigned int))objc_msgSend)(manager, modeSelector, mediaItem, 1);
    } else if ([manager respondsToSelector:fallbackSelector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(manager, fallbackSelector, mediaItem);
    } else {
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        SEL pathSelector = sel_registerName("getFormatVideoPath");
        NSString *path = nil;
        for (NSUInteger attempt = 0; attempt < 301; attempt++) {
            id value = [mediaItem respondsToSelector:pathSelector]
                ? ((id (*)(id, SEL))objc_msgSend)(mediaItem, pathSelector) : nil;
            if ([value isKindOfClass:NSString.class] && [NSFileManager.defaultManager fileExistsAtPath:value]) {
                path = value;
                break;
            }
            [NSThread sleepForTimeInterval:1.0];
        }
        if (path.length > 0) NeoWCMomentsReminderSendVideo(target, path);
        else NeoWCLog(@"朋友圈视频下载超时");
    });
}

static NSString *NeoWCMomentsReminderContentTypeName(id dataItem) {
    id contentObject = NeoWCMomentsReminderObjectValue(dataItem, "contentObj");
    uint64_t type = NeoWCMomentsReminderIntegerValue(contentObject, "type");
    if (type == 1 || type == 54) return @"图片";
    if (type == 15) return @"视频";
    return @"文字";
}

static void NeoWCMomentsReminderForwardItem(id dataItem, NSString *username, NSString *nickname,
                                            NSString *content, uint64_t createdAt) {
    if (!NeoWCEnhancementEnabled(NeoWCMomentsReminderForwardEnabledKey) || !dataItem) return;
    NSString *target = NeoWCMomentsReminderForwardTarget();
    if (target.length == 0) return;
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *name = nickname.length > 0 ? nickname : username;
    NSString *copyText = content.length > 0 ? [NSString stringWithFormat:@"文案: %@", content] : @"";
    NSString *message = [NSString stringWithFormat:@"【朋友圈特别关注】\n好友: %@\n类型: %@\n时间: %@\n%@",
                         name ?: @"", NeoWCMomentsReminderContentTypeName(dataItem),
                         [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:createdAt]], copyText];
    NeoWCMomentsReminderSendText(target, message);

    id contentObject = NeoWCMomentsReminderObjectValue(dataItem, "contentObj");
    uint64_t type = NeoWCMomentsReminderIntegerValue(contentObject, "type");
    NSArray *mediaList = NeoWCMomentsReminderMediaList(dataItem);
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults boolForKey:NeoWCMomentsReminderForwardImagesKey] && (type == 1 || type == 54)) {
        for (id mediaItem in mediaList) NeoWCMomentsReminderDownloadImage(mediaItem, target);
    }
    if ([defaults boolForKey:NeoWCMomentsReminderForwardVideosKey]) {
        if (type == 15 && mediaList.count > 0) {
            NeoWCMomentsReminderDownloadVideo(mediaList.firstObject, target);
        } else if (type == 54) {
            for (id mediaItem in mediaList) {
                id liveMedia = NeoWCMomentsReminderObjectValue(mediaItem, "livePhotoMediaItem");
                if (liveMedia) NeoWCMomentsReminderDownloadVideo(liveMedia, target);
            }
        }
    }
}

static id NeoWCMomentsReminderContact(NSString *username) {
    Class contextClass = objc_getClass("MMContext");
    SEL activeSelector = sel_registerName("activeUserContext");
    SEL serviceSelector = sel_registerName("getService:");
    Class managerClass = objc_getClass("CContactMgr");
    if (!contextClass || !managerClass || ![contextClass respondsToSelector:activeSelector]) return nil;
    id context = ((id (*)(id, SEL))objc_msgSend)(contextClass, activeSelector);
    if (!context || ![context respondsToSelector:serviceSelector]) return nil;
    id manager = ((id (*)(id, SEL, Class))objc_msgSend)(context, serviceSelector, managerClass);
    SEL contactSelector = sel_registerName("getContactByName:");
    if (!manager || ![manager respondsToSelector:contactSelector]) return nil;
    return ((id (*)(id, SEL, id))objc_msgSend)(manager, contactSelector, username);
}

static void NeoWCMomentsReminderShowForegroundToast(NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        for (UIWindow *candidate in UIApplication.sharedApplication.windows.reverseObjectEnumerator) {
            if (!candidate.hidden && candidate.alpha > 0.0 && candidate.windowLevel == UIWindowLevelNormal) {
                window = candidate;
                if (candidate.isKeyWindow) break;
            }
        }
        if (!window || message.length == 0) return;
        const NSInteger toastTag = 0x4E574D52;
        [[window viewWithTag:toastTag] removeFromSuperview];
        UIView *toast = [UIView new];
        toast.tag = toastTag;
        toast.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.9];
        toast.layer.cornerRadius = 13.0;
        toast.layer.cornerCurve = kCACornerCurveContinuous;
        toast.layer.masksToBounds = YES;
        toast.translatesAutoresizingMaskIntoConstraints = NO;
        UILabel *label = [UILabel new];
        label.text = message;
        label.textColor = UIColor.whiteColor;
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        label.adjustsFontForContentSizeCategory = YES;
        label.numberOfLines = 2;
        label.textAlignment = NSTextAlignmentCenter;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [toast addSubview:label];
        [window addSubview:toast];
        [NSLayoutConstraint activateConstraints:@[
            [toast.centerXAnchor constraintEqualToAnchor:window.centerXAnchor],
            [toast.centerYAnchor constraintEqualToAnchor:window.centerYAnchor],
            [toast.widthAnchor constraintGreaterThanOrEqualToConstant:220.0],
            [toast.leadingAnchor constraintGreaterThanOrEqualToAnchor:window.leadingAnchor constant:24.0],
            [toast.trailingAnchor constraintLessThanOrEqualToAnchor:window.trailingAnchor constant:-24.0],
            [toast.heightAnchor constraintGreaterThanOrEqualToConstant:48.0],
            [label.leadingAnchor constraintEqualToAnchor:toast.leadingAnchor constant:18.0],
            [label.trailingAnchor constraintEqualToAnchor:toast.trailingAnchor constant:-18.0],
            [label.topAnchor constraintEqualToAnchor:toast.topAnchor constant:12.0],
            [label.bottomAnchor constraintEqualToAnchor:toast.bottomAnchor constant:-12.0],
        ]];
        toast.alpha = 0.0;
        [UIView animateWithDuration:0.2 animations:^{ toast.alpha = 1.0; } completion:^(__unused BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.2 animations:^{ toast.alpha = 0.0; }
                                 completion:^(__unused BOOL hidden) { [toast removeFromSuperview]; }];
            });
        }];
    });
}

static void NeoWCMomentsReminderNotify(NSString *username, NSString *nickname, NSString *content, uint64_t createdAt, NSString *tid) {
    NSString *name = nickname.length > 0 ? nickname : username;
    if (name.length == 0) name = @"好友";
    NSString *body = content.length > 0 ? [NSString stringWithFormat:@"%@：%@", name, content] :
                                          [NSString stringWithFormat:@"%@ 发布了新朋友圈", name];
    if (body.length > 180) body = [[body substringToIndex:177] stringByAppendingString:@"…"];
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
        NeoWCMomentsReminderShowForegroundToast([NSString stringWithFormat:@"您关注的%@朋友圈已更新", name]);
        return;
    }

    UNMutableNotificationContent *notification = [UNMutableNotificationContent new];
    notification.title = @"朋友圈提醒";
    notification.body = body;
    notification.sound = UNNotificationSound.defaultSound;
    notification.userInfo = @{ @"neowc": @"moments-reminder", @"username": username ?: @"", @"tid": tid ?: @"" };
    NSString *identifier = [NSString stringWithFormat:@"neowc.moments.%@.%@.%llu", username ?: @"unknown", tid ?: @"unknown", createdAt];
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1.0 repeats:NO];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:notification trigger:trigger];
    [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request withCompletionHandler:^(NSError *error) {
        if (error) NeoWCLog(@"发送朋友圈提醒失败：%@", error.localizedDescription ?: @"未知错误");
    }];
}

@interface NeoWCMomentsReminderManager : NSObject
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *controllers;
@property (nonatomic, assign) NSTimeInterval lastCheckTime;
@property (nonatomic, assign) BOOL checking;
+ (instancetype)sharedManager;
- (void)tick;
- (void)performCheck;
- (void)settingsDidChange;
@end

@implementation NeoWCMomentsReminderManager

+ (instancetype)sharedManager {
    static NeoWCMomentsReminderManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [NeoWCMomentsReminderManager new];
        manager.controllers = [NSMutableDictionary dictionary];
    });
    return manager;
}

- (NSTimeInterval)checkInterval {
    NSTimeInterval interval = [NSUserDefaults.standardUserDefaults doubleForKey:NeoWCMomentsReminderIntervalKey];
    return MIN(3600.0, MAX(30.0, interval > 0.0 ? interval : 60.0));
}

- (id)controllerForUsername:(NSString *)username {
    id controller = self.controllers[username];
    if (controller) return controller;
    Class controllerClass = objc_getClass("WCListViewController");
    id contact = NeoWCMomentsReminderContact(username);
    if (!controllerClass || !contact) return nil;
    controller = [[controllerClass alloc] init];
    SEL setContactSelector = sel_registerName("setM_contact:");
    if (![controller respondsToSelector:setContactSelector]) return nil;
    ((void (*)(id, SEL, id))objc_msgSend)(controller, setContactSelector, contact);
    self.controllers[username] = controller;
    return controller;
}

- (NSArray *)loadItemsForUsername:(NSString *)username success:(BOOL *)success {
    if (success) *success = NO;
    id controller = [self controllerForUsername:username];
    SEL initDataSelector = sel_registerName("initData:");
    Method initDataMethod = controller ? class_getInstanceMethod([controller class], initDataSelector) : NULL;
    const char *initDataEncoding = initDataMethod ? method_getTypeEncoding(initDataMethod) : NULL;
    if (!initDataEncoding || strcmp(initDataEncoding, "v20@0:8B16") != 0) {
        NeoWCLog(@"读取 %@ 的朋友圈数据失败：initData: ABI 不匹配", username);
        return @[];
    }
    @try {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(controller, initDataSelector, YES);
        id value = [controller valueForKey:@"m_arrPhotoDatas"];
        if (![value isKindOfClass:NSArray.class]) return @[];
        if (success) *success = YES;
        return [value copy];
    } @catch (NSException *exception) {
        NeoWCLog(@"读取 %@ 的朋友圈数据失败：%@", username, exception.reason ?: @"未知异常");
        return @[];
    }
}

- (void)processItems:(NSArray *)items username:(NSString *)username seenRoot:(NSMutableDictionary *)seenRoot account:(NSString *)account {
    if (username.length == 0) return;
    NSMutableDictionary *accountSeen = [seenRoot[account] isKindOfClass:NSDictionary.class]
        ? [seenRoot[account] mutableCopy] : [NSMutableDictionary dictionary];
    BOOL hasBaseline = [accountSeen[username] isKindOfClass:NSArray.class];
    NSArray<NSString *> *previouslySeen = hasBaseline ? accountSeen[username] : @[];
    NSSet<NSString *> *previouslySeenSet = [NSSet setWithArray:previouslySeen];
    NSMutableOrderedSet<NSString *> *currentTids = [NSMutableOrderedSet orderedSet];
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    NSMutableArray<NSDictionary *> *newItems = [NSMutableArray array];

    for (id item in items) {
        NSString *tid = NeoWCMomentsReminderString(NeoWCMomentsReminderObjectValue(item, "tid"));
        if (tid.length == 0) continue;
        BOOL alreadySeen = [previouslySeenSet containsObject:tid];
        [currentTids addObject:tid];
        if (!hasBaseline || alreadySeen) continue;
        uint64_t createdAt = NeoWCMomentsReminderIntegerValue(item, "createtime");
        if (createdAt == 0 || now - (NSTimeInterval)createdAt > 86400.0) continue;
        NSString *nickname = NeoWCMomentsReminderString(NeoWCMomentsReminderObjectValue(item, "nickname"));
        NSString *content = NeoWCMomentsReminderString(NeoWCMomentsReminderObjectValue(item, "contentDesc"));
        [newItems addObject:@{ @"tid": tid,
                               @"createdAt": @(createdAt),
                               @"nickname": nickname ?: @"",
                               @"content": content ?: @"",
                               @"dataItem": item }];
    }

    NSMutableOrderedSet<NSString *> *mergedSeen = [NSMutableOrderedSet orderedSetWithOrderedSet:currentTids];
    [mergedSeen addObjectsFromArray:previouslySeen];
    while (mergedSeen.count > 200) [mergedSeen removeObjectAtIndex:mergedSeen.count - 1];
    accountSeen[username] = mergedSeen.array;
    seenRoot[account] = accountSeen;
    for (NSDictionary *item in [newItems sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *left, NSDictionary *right) {
        return [left[@"createdAt"] compare:right[@"createdAt"]];
    }]) {
        NeoWCMomentsReminderNotify(username, item[@"nickname"], item[@"content"],
                                   [item[@"createdAt"] unsignedLongLongValue], item[@"tid"]);
        NeoWCMomentsReminderForwardItem(item[@"dataItem"], username, item[@"nickname"], item[@"content"],
                                        [item[@"createdAt"] unsignedLongLongValue]);
    }
}

- (void)tick {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self tick]; });
        return;
    }
    if (self.checking || !NeoWCEnhancementEnabled(NeoWCMomentsReminderEnabledKey)) return;
    NSArray<NSString *> *users = NeoWCMomentsReminderUsers();
    if (users.count == 0) return;
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    if (self.lastCheckTime > 0.0 && now - self.lastCheckTime < [self checkInterval]) return;
    self.lastCheckTime = now;
    self.checking = YES;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self performCheck];
    });
}

- (void)performCheck {
    if (!NeoWCEnhancementEnabled(NeoWCMomentsReminderEnabledKey)) {
        self.checking = NO;
        return;
    }
    NSArray<NSString *> *users = NeoWCMomentsReminderUsers();
    if (users.count == 0) {
        self.checking = NO;
        return;
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSMutableDictionary *seenRoot = [[defaults dictionaryForKey:NeoWCMomentsReminderSeenItemsKey] mutableCopy] ?: [NSMutableDictionary dictionary];
    NSString *account = NeoWCCurrentUserWXID() ?: @"default";
    for (NSString *username in users) {
        BOOL loaded = NO;
        NSArray *items = [self loadItemsForUsername:username success:&loaded];
        if (loaded) {
            [self processItems:items username:username seenRoot:seenRoot account:account];
        }
    }
    [defaults setObject:seenRoot forKey:NeoWCMomentsReminderSeenItemsKey];
    self.checking = NO;
}

- (void)settingsDidChange {
    self.lastCheckTime = 0.0;
    NSSet *selected = [NSSet setWithArray:NeoWCMomentsReminderUsers()];
    for (NSString *username in self.controllers.allKeys.copy) {
        if (![selected containsObject:username]) [self.controllers removeObjectForKey:username];
    }
    if (NeoWCEnhancementEnabled(NeoWCMomentsReminderEnabledKey)) [self tick];
}

@end

void NeoWCMomentsReminderTick(void) {
    [[NeoWCMomentsReminderManager sharedManager] tick];
}

void NeoWCMomentsReminderSettingsDidChange(void) {
    [[NeoWCMomentsReminderManager sharedManager] settingsDidChange];
}
