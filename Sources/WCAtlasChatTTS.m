#import "WCAtlasChatTTS.h"
#import "WCAtlasPrivateAPI.h"
#import "WCAtlasSilkEncoder.h"
#import "WCAtlasTTSGenerator.h"
#import "WCAtlasLogging.h"
#import "WCAtlasEnhancements.h"

static NSMutableSet<NSString *> *WCAtlasChatTTSActiveSessions(void) {
    static NSMutableSet<NSString *> *sessions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ sessions = [NSMutableSet set]; });
    return sessions;
}

static NSString *WCAtlasChatTTSTrim(id value) {
    return [value isKindOfClass:NSString.class]
        ? [(NSString *)value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]
        : @"";
}

static NSString *WCAtlasChatTTSVoiceName(void) {
    NSString *selected = WCAtlasFishAudioReferenceID();
    if (selected.length == 0) return @"默认音色";
    for (NSDictionary<NSString *, NSString *> *preset in WCAtlasFishAudioVoicePresets()) {
        if ([preset[@"referenceID"] isEqualToString:selected]) return preset[@"name"] ?: @"自定义音色";
    }
    return @"自定义音色";
}

static NSString *WCAtlasChatTTSReferenceIDFromInput(NSString *input) {
    NSString *value = WCAtlasChatTTSTrim(input);
    if (value.length == 0) return @"";
    NSURLComponents *components = [NSURLComponents componentsWithString:value];
    for (NSURLQueryItem *item in components.queryItems ?: @[]) {
        if ([item.name isEqualToString:@"modelId"] && item.value.length > 0) return item.value;
    }
    NSArray<NSString *> *parts = components.URL.pathComponents;
    NSUInteger marker = [parts indexOfObject:@"m"];
    if (marker != NSNotFound && marker + 1 < parts.count) return parts[marker + 1];
    return value;
}

static void WCAtlasChatTTSReport(WCAtlasChatTTSStatusHandler status,
                                 NSString *message, BOOL success) {
    WCAtlasLog(@"聊天 TTS：%@", message ?: @"");
    if (status) status(message ?: @"", success);
}

static BOOL WCAtlasChatTTSStillInConversation(UIViewController *presenter, NSString *userName) {
    if (!presenter.viewIfLoaded.window || userName.length == 0) return NO;
    UIViewController *current = WCAtlasPrivateCurrentChatController();
    return current == presenter && [WCAtlasPrivateChatUserName(current) isEqualToString:userName];
}

static void WCAtlasChatTTSGenerateAndSend(UIViewController *presenter,
                                         NSString *userName,
                                         NSString *text,
                                         dispatch_block_t didSubmit,
                                         WCAtlasChatTTSStatusHandler status) {
    NSCAssert(NSThread.isMainThread, @"Chat TTS must start on the main thread");
    NSString *target = WCAtlasChatTTSTrim(userName);
    NSString *content = WCAtlasChatTTSTrim(text);
    if (target.length == 0 || !WCAtlasChatTTSStillInConversation(presenter, target)) {
        WCAtlasChatTTSReport(status, @"当前聊天已经变化，未发送", NO);
        return;
    }
    if (content.length == 0) {
        WCAtlasChatTTSReport(status, @"请输入需要转成语音的内容", NO);
        return;
    }
    NSMutableSet<NSString *> *active = WCAtlasChatTTSActiveSessions();
    if ([active containsObject:target]) {
        WCAtlasChatTTSReport(status, @"当前聊天已有一条 TTS 正在生成", NO);
        return;
    }
    [active addObject:target];
    WCAtlasChatTTSReport(status, @"正在请求 Fish Audio…", YES);
    __weak UIViewController *weakPresenter = presenter;
    WCAtlasGenerateFishAudioSpeech(content, ^(NSURL *outputURL, NSError *generationError) {
        if (generationError || !outputURL) {
            [active removeObject:target];
            WCAtlasChatTTSReport(status, generationError.localizedDescription ?: @"TTS 生成失败", NO);
            return;
        }
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            NSString *silkPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
                [NSString stringWithFormat:@"WCAtlas-chat-tts-%@.silk", NSUUID.UUID.UUIDString]];
            NSUInteger duration = 0;
            NSError *conversionError = nil;
            BOOL converted = WCAtlasEncodeAudioFileToSilk(outputURL.path, silkPath, &duration, &conversionError);
            [NSFileManager.defaultManager removeItemAtURL:outputURL error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [active removeObject:target];
                UIViewController *strongPresenter = weakPresenter;
                if (!converted) {
                    [NSFileManager.defaultManager removeItemAtPath:silkPath error:nil];
                    WCAtlasChatTTSReport(status, conversionError.localizedDescription ?: @"TTS 音频转码失败", NO);
                    return;
                }
                if (!WCAtlasChatTTSStillInConversation(strongPresenter, target)) {
                    [NSFileManager.defaultManager removeItemAtPath:silkPath error:nil];
                    WCAtlasChatTTSReport(status, @"生成完成，但当前聊天已经变化，未发送", NO);
                    return;
                }
                BOOL submitted = WCAtlasPrivateSendVoiceMessage(target, silkPath, duration, 4);
                [NSFileManager.defaultManager removeItemAtPath:silkPath error:nil];
                if (!submitted) {
                    WCAtlasChatTTSReport(status, @"微信语音上传接口不可用，未发送", NO);
                    return;
                }
                if (didSubmit) didSubmit();
                WCAtlasChatTTSReport(status, @"已提交 TTS 语音发送", YES);
            });
        });
    });
}

static void WCAtlasChatTTSPresentMainPanel(UIViewController *, NSString *, dispatch_block_t,
                                           WCAtlasChatTTSStatusHandler);

static void WCAtlasChatTTSPresentModelPicker(UIViewController *presenter, NSString *userName,
                                             dispatch_block_t didSubmit,
                                             WCAtlasChatTTSStatusHandler status) {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Fish Audio 模型"
        message:@"免费模型优先使用免费额度；付费模型需要账户余额。"
        preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *model in @[@"s2.1-pro-free", @"s2.1-pro", @"s2-pro"]) {
        NSString *title = [model isEqualToString:WCAtlasFishAudioModel()]
            ? [@"✓  " stringByAppendingString:model] : model;
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault
            handler:^(__unused UIAlertAction *action) {
                WCAtlasSetFishAudioModel(model);
                WCAtlasChatTTSReport(status, [NSString stringWithFormat:@"已选择模型：%@", model], YES);
            }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"返回" style:UIAlertActionStyleCancel
        handler:^(__unused UIAlertAction *action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                WCAtlasChatTTSPresentMainPanel(presenter, userName, didSubmit, status);
            });
        }]];
    sheet.popoverPresentationController.sourceView = presenter.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(presenter.view.bounds),
        CGRectGetMidY(presenter.view.bounds), 1, 1);
    [presenter presentViewController:sheet animated:YES completion:nil];
}

static void WCAtlasChatTTSPresentAddVoice(UIViewController *presenter,
                                          WCAtlasChatTTSStatusHandler status) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加音色"
        message:@"支持 reference_id、包含 modelId 的链接或 fish.audio/m/ 链接。"
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"音色名称"; }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"音色 ID 或链接";
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
    }];
    __weak UIAlertController *weakAlert = alert;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"添加并使用" style:UIAlertActionStyleDefault
        handler:^(__unused UIAlertAction *action) {
            NSString *name = WCAtlasChatTTSTrim(weakAlert.textFields.firstObject.text);
            NSString *input = weakAlert.textFields.count > 1 ? weakAlert.textFields[1].text : @"";
            NSString *referenceID = WCAtlasChatTTSReferenceIDFromInput(input);
            if (!WCAtlasAddFishAudioVoicePreset(name, referenceID)) {
                WCAtlasChatTTSReport(status, @"音色名称和 ID 不能为空", NO);
                return;
            }
            WCAtlasSetFishAudioReferenceID(referenceID);
            WCAtlasChatTTSReport(status, [NSString stringWithFormat:@"已添加并选择音色：%@", name], YES);
        }]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

static void WCAtlasChatTTSPresentDeleteVoice(UIViewController *presenter,
                                             WCAtlasChatTTSStatusHandler status) {
    NSArray<NSDictionary<NSString *, NSString *> *> *presets = WCAtlasFishAudioVoicePresets();
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"删除音色预设"
        message:presets.count ? @"删除后不会自动恢复。" : @"当前没有可删除的音色。"
        preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSDictionary<NSString *, NSString *> *preset in presets) {
        NSString *name = preset[@"name"];
        NSString *referenceID = preset[@"referenceID"];
        [sheet addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDestructive
            handler:^(__unused UIAlertAction *action) {
                WCAtlasRemoveFishAudioVoicePreset(referenceID);
                WCAtlasChatTTSReport(status, [NSString stringWithFormat:@"已删除音色：%@", name], YES);
            }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = presenter.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(presenter.view.bounds),
        CGRectGetMidY(presenter.view.bounds), 1, 1);
    [presenter presentViewController:sheet animated:YES completion:nil];
}

static void WCAtlasChatTTSPresentVoicePicker(UIViewController *presenter,
                                             WCAtlasChatTTSStatusHandler status) {
    NSString *selected = WCAtlasFishAudioReferenceID();
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"选择 TTS 音色"
        message:@"选择结果同时用于聊天 TTS 和通话 TTS。"
        preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:selected.length ? @"默认音色" : @"✓  默认音色"
        style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            WCAtlasSetFishAudioReferenceID(nil);
            WCAtlasChatTTSReport(status, @"已选择默认音色", YES);
        }]];
    for (NSDictionary<NSString *, NSString *> *preset in WCAtlasFishAudioVoicePresets()) {
        NSString *name = preset[@"name"];
        NSString *referenceID = preset[@"referenceID"];
        NSString *title = [referenceID isEqualToString:selected] ? [@"✓  " stringByAppendingString:name] : name;
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault
            handler:^(__unused UIAlertAction *action) {
                WCAtlasSetFishAudioReferenceID(referenceID);
                WCAtlasChatTTSReport(status, [NSString stringWithFormat:@"已选择音色：%@", name], YES);
            }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"添加音色" style:UIAlertActionStyleDefault
        handler:^(__unused UIAlertAction *action) {
            dispatch_async(dispatch_get_main_queue(), ^{ WCAtlasChatTTSPresentAddVoice(presenter, status); });
        }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"删除音色" style:UIAlertActionStyleDestructive
        handler:^(__unused UIAlertAction *action) {
            dispatch_async(dispatch_get_main_queue(), ^{ WCAtlasChatTTSPresentDeleteVoice(presenter, status); });
        }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = presenter.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(presenter.view.bounds),
        CGRectGetMidY(presenter.view.bounds), 1, 1);
    [presenter presentViewController:sheet animated:YES completion:nil];
}

static void WCAtlasChatTTSPresentAPISettings(UIViewController *presenter,
                                             WCAtlasChatTTSStatusHandler status) {
    BOOL hasKey = WCAtlasFishAudioAPIKey().length > 0;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Fish Audio 设置"
        message:[NSString stringWithFormat:@"当前模型：%@\nAPI Key 只保存在本机 Keychain。", WCAtlasFishAudioModel()]
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = hasKey ? @"Key 已保存，留空保持不变" : @"Fish Audio API Key";
        field.secureTextEntry = YES;
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
    }];
    __weak UIAlertController *weakAlert = alert;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"获取 Key" style:UIAlertActionStyleDefault
        handler:^(__unused UIAlertAction *action) {
            NSURL *URL = WCAtlasFishAudioAPIKeysURL();
            if (URL) [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:nil];
        }]];
    if (hasKey) {
        [alert addAction:[UIAlertAction actionWithTitle:@"删除 Key" style:UIAlertActionStyleDestructive
            handler:^(__unused UIAlertAction *action) {
                NSError *error = nil;
                WCAtlasSetFishAudioAPIKey(@"", &error);
                WCAtlasChatTTSReport(status, error.localizedDescription ?: @"API Key 已删除", error == nil);
            }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault
        handler:^(__unused UIAlertAction *action) {
            NSString *key = WCAtlasChatTTSTrim(weakAlert.textFields.firstObject.text);
            if (key.length == 0) {
                WCAtlasChatTTSReport(status, hasKey ? @"API Key 保持不变" : @"未填写 API Key", hasKey);
                return;
            }
            NSError *error = nil;
            BOOL saved = WCAtlasSetFishAudioAPIKey(key, &error);
            WCAtlasChatTTSReport(status, saved ? @"API Key 已保存" : (error.localizedDescription ?: @"API Key 保存失败"), saved);
        }]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

static void WCAtlasChatTTSPresentTriggerSettings(UIViewController *presenter,
                                                 WCAtlasChatTTSStatusHandler status) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    BOOL enabled = [defaults boolForKey:WCAtlasChatTTSTriggerEnabledKey];
    NSString *prefix = WCAtlasChatTTSTrim([defaults stringForKey:WCAtlasChatTTSTriggerPrefixKey]);
    if (prefix.length == 0) prefix = @"转语音";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"文字触发转语音"
        message:[NSString stringWithFormat:@"当前：%@\n发送“%@你好”时，将拦截文字并发送 TTS 语音。",
                 enabled ? @"已开启" : @"已关闭", prefix]
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"触发前缀，例如：转语音";
        field.text = prefix;
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    __weak UIAlertController *weakAlert = alert;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    void (^savePrefix)(void) = ^{
        NSString *newPrefix = WCAtlasChatTTSTrim(weakAlert.textFields.firstObject.text);
        if (newPrefix.length == 0) {
            WCAtlasChatTTSReport(status, @"触发前缀不能为空", NO);
            return;
        }
        [defaults setObject:newPrefix forKey:WCAtlasChatTTSTriggerPrefixKey];
        WCAtlasChatTTSReport(status,
            [NSString stringWithFormat:@"触发前缀已保存：%@（%@）", newPrefix,
             [defaults boolForKey:WCAtlasChatTTSTriggerEnabledKey] ? @"已开启" : @"已关闭"], YES);
    };
    [alert addAction:[UIAlertAction actionWithTitle:@"保存前缀"
        style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            savePrefix();
        }]];
    [alert addAction:[UIAlertAction actionWithTitle:enabled ? @"关闭触发" : @"开启触发"
        style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            NSString *newPrefix = WCAtlasChatTTSTrim(weakAlert.textFields.firstObject.text);
            if (newPrefix.length == 0) {
                WCAtlasChatTTSReport(status, @"触发前缀不能为空", NO);
                return;
            }
            [defaults setObject:newPrefix forKey:WCAtlasChatTTSTriggerPrefixKey];
            [defaults setBool:!enabled forKey:WCAtlasChatTTSTriggerEnabledKey];
            WCAtlasChatTTSReport(status,
                [NSString stringWithFormat:@"文字触发已%@：%@", enabled ? @"关闭" : @"开启", newPrefix], YES);
        }]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

static void WCAtlasChatTTSPresentTextInput(UIViewController *presenter, NSString *userName,
                                           dispatch_block_t didSubmit,
                                           WCAtlasChatTTSStatusHandler status) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"发送 TTS 语音"
        message:[NSString stringWithFormat:@"%@ · %@ · %@", WCAtlasFishAudioModel(),
                 WCAtlasChatTTSVoiceName(), WCAtlasFishAudioAPIKey().length ? @"Key 已配置" : @"未配置 Key"]
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"输入要转换并发送的文字";
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    __weak UIAlertController *weakAlert = alert;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"生成并发送" style:UIAlertActionStyleDefault
        handler:^(__unused UIAlertAction *action) {
            WCAtlasChatTTSGenerateAndSend(presenter, userName,
                weakAlert.textFields.firstObject.text ?: @"", didSubmit, status);
        }]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

static void WCAtlasChatTTSPresentMainPanel(UIViewController *presenter, NSString *userName,
                                           dispatch_block_t didSubmit,
                                           WCAtlasChatTTSStatusHandler status) {
    if (!presenter.viewIfLoaded.window) return;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    BOOL triggerEnabled = [defaults boolForKey:WCAtlasChatTTSTriggerEnabledKey];
    NSString *prefix = WCAtlasChatTTSTrim([defaults stringForKey:WCAtlasChatTTSTriggerPrefixKey]);
    if (prefix.length == 0) prefix = @"转语音";
    NSString *message = [NSString stringWithFormat:@"%@ · %@\n文字触发：%@（%@）",
        WCAtlasFishAudioModel(), WCAtlasChatTTSVoiceName(), prefix, triggerEnabled ? @"已开启" : @"已关闭"];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"聊天 TTS"
        message:message preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"输入文字并发送语音" style:UIAlertActionStyleDefault
        handler:^(__unused UIAlertAction *action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                WCAtlasChatTTSPresentTextInput(presenter, userName, didSubmit, status);
            });
        }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"选择音色" style:UIAlertActionStyleDefault
        handler:^(__unused UIAlertAction *action) {
            dispatch_async(dispatch_get_main_queue(), ^{ WCAtlasChatTTSPresentVoicePicker(presenter, status); });
        }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"选择模型" style:UIAlertActionStyleDefault
        handler:^(__unused UIAlertAction *action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                WCAtlasChatTTSPresentModelPicker(presenter, userName, didSubmit, status);
            });
        }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"设置文字触发" style:UIAlertActionStyleDefault
        handler:^(__unused UIAlertAction *action) {
            dispatch_async(dispatch_get_main_queue(), ^{ WCAtlasChatTTSPresentTriggerSettings(presenter, status); });
        }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Fish Audio API Key" style:UIAlertActionStyleDefault
        handler:^(__unused UIAlertAction *action) {
            dispatch_async(dispatch_get_main_queue(), ^{ WCAtlasChatTTSPresentAPISettings(presenter, status); });
        }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = presenter.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(presenter.view.bounds),
        CGRectGetMidY(presenter.view.bounds), 1, 1);
    [presenter presentViewController:sheet animated:YES completion:nil];
}

void WCAtlasPresentChatTTSPanel(UIViewController *presenter, NSString *userName,
                                dispatch_block_t didSubmit, WCAtlasChatTTSStatusHandler status) {
    NSCAssert(NSThread.isMainThread, @"Chat TTS panel must be presented on the main thread");
    if (!presenter || userName.length == 0) {
        WCAtlasChatTTSReport(status, @"当前页面不是可用的聊天会话", NO);
        return;
    }
    WCAtlasChatTTSPresentMainPanel(presenter, userName, didSubmit, status);
}

BOOL WCAtlasChatTTSConsumeTriggeredText(UIViewController *presenter, NSString *userName,
                                        NSString *text, dispatch_block_t didSubmit,
                                        WCAtlasChatTTSStatusHandler status) {
    NSCAssert(NSThread.isMainThread, @"Chat TTS trigger must run on the main thread");
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if (![defaults boolForKey:WCAtlasChatTTSTriggerEnabledKey]) return NO;
    NSString *prefix = WCAtlasChatTTSTrim([defaults stringForKey:WCAtlasChatTTSTriggerPrefixKey]);
    if (prefix.length == 0) prefix = @"转语音";
    if (![text isKindOfClass:NSString.class] || ![text hasPrefix:prefix]) return NO;
    NSString *content = [text substringFromIndex:prefix.length];
    NSCharacterSet *separators = [NSCharacterSet characterSetWithCharactersInString:@" \t\r\n:：+＋➕"];
    content = [content stringByTrimmingCharactersInSet:separators];
    if (content.length == 0) {
        WCAtlasChatTTSReport(status, [NSString stringWithFormat:@"请在“%@”后输入内容", prefix], NO);
        return YES;
    }
    WCAtlasChatTTSGenerateAndSend(presenter, userName, content, didSubmit, status);
    return YES;
}
