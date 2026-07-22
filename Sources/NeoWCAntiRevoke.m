#import "NeoWCAntiRevoke.h"

#import <objc/message.h>
#import <objc/runtime.h>

#import "NeoWCDebug.h"
#import "NeoWCEnhancements.h"

static NSUInteger NeoWCUIntegerValue(id object, NSString *key);

NSString *const NeoWCAntiRevokePromptDidChangeNotification = @"NeoWCAntiRevokePromptDidChangeNotification";
static NSString *const NeoWCAntiRevokeSidePromptRecordsKey = @"com.qiu7c.neowc.message.anti-revoke.side-records";
static NSString *const NeoWCAntiRevokeArchiveKey = @"com.qiu7c.neowc.message.anti-revoke.archive";
static NSString *const NeoWCAntiRevokeLocalPromptContentsKey = @"com.qiu7c.neowc.message.anti-revoke.local-prompt-contents";

static NSMutableArray<NSDictionary *> *NeoWCAntiRevokeMemoryRecords(void) {
    static NSMutableArray<NSDictionary *> *records;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *saved = [[NSUserDefaults standardUserDefaults] arrayForKey:NeoWCAntiRevokeArchiveKey];
        records = [([saved isKindOfClass:[NSArray class]] ? saved : @[]) mutableCopy];
    });
    return records;
}

void NeoWCAntiRevokeSetPersistenceEnabled(BOOL enabled) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setBool:enabled forKey:NeoWCAntiRevokePersistRecordsKey];
    if (enabled) {
        @synchronized (NeoWCAntiRevokeMemoryRecords()) { [defaults setObject:NeoWCAntiRevokeMemoryRecords() forKey:NeoWCAntiRevokeArchiveKey]; }
    } else {
        [defaults removeObjectForKey:NeoWCAntiRevokeArchiveKey];
    }
}

static void NeoWCAntiRevokeAppendRecord(NSString *session, NSString *operatorName, id message, NSString *summary, NSDate *date) {
    NSUInteger type = NeoWCUIntegerValue(message, @"m_uiMessageType");
    NSDictionary *record = @{
        @"session": session ?: @"",
        @"contact": operatorName ?: @"用户",
        @"summary": summary ?: @"",
        @"type": @(type),
        @"time": @((date ?: [NSDate date]).timeIntervalSince1970),
    };
    @synchronized (NeoWCAntiRevokeMemoryRecords()) {
        [NeoWCAntiRevokeMemoryRecords() insertObject:record atIndex:0];
        if (NeoWCAntiRevokeMemoryRecords().count > 500) {
            [NeoWCAntiRevokeMemoryRecords() removeObjectsInRange:NSMakeRange(500, NeoWCAntiRevokeMemoryRecords().count - 500)];
        }
        if ([[NSUserDefaults standardUserDefaults] boolForKey:NeoWCAntiRevokePersistRecordsKey]) {
            [[NSUserDefaults standardUserDefaults] setObject:NeoWCAntiRevokeMemoryRecords() forKey:NeoWCAntiRevokeArchiveKey];
        }
    }
}

static NSString *const NeoWCDefaultLocalRevokeTemplate =
    @"拦截到一条{用户名}撤回的消息\n发送时间：{yyyy}-{MM}-{dd} {HH}:{mm}:{ss}\n内容：{内容}";

static NSString *const NeoWCDefaultRevokeReplyTemplate =
    @"【捕捉到一条撤回消息】\n操作用户：{用户名}\n发送时间：{yyyy}-{MM}-{dd} {HH}:{mm}:{ss}\n"
    @"撤回内容：{内容}\n\n撤回无效，消息已保存";

static id NeoWCSafeValue(id object, NSString *key) {
    if (!object || key.length == 0) return nil;
    @try {
        return [object valueForKey:key];
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static void NeoWCSafeSetValue(id object, NSString *key, id value) {
    if (!object || key.length == 0) return;
    @try {
        [object setValue:value forKey:key];
    } @catch (__unused NSException *exception) {}
}

static NSString *NeoWCStringValue(id object, NSString *key) {
    id value = NeoWCSafeValue(object, key);
    return [value isKindOfClass:[NSString class]] ? value : nil;
}

static NSUInteger NeoWCUIntegerValue(id object, NSString *key) {
    id value = NeoWCSafeValue(object, key);
    return [value respondsToSelector:@selector(unsignedIntegerValue)] ? [value unsignedIntegerValue] : 0;
}

static unsigned long long NeoWCUInt64Value(id object, NSString *key) {
    id value = NeoWCSafeValue(object, key);
    if (![value respondsToSelector:@selector(unsignedLongLongValue)]) return 0;
    return [value unsignedLongLongValue];
}

static NSArray<NSString *> *NeoWCSidePromptRecordKeys(id message) {
    unsigned long long serverID = NeoWCUInt64Value(message, @"m_n64MesSvrID");
    unsigned long long localID = NeoWCUInt64Value(message, @"m_uiMesLocalID");
    NSMutableArray<NSString *> *keys = [NSMutableArray arrayWithCapacity:2];
    if (serverID > 0) [keys addObject:[NSString stringWithFormat:@"server:%llu", serverID]];
    if (localID > 0) [keys addObject:[NSString stringWithFormat:@"local:%llu", localID]];
    return keys;
}

NSString *NeoWCAntiRevokeSidePromptForMessage(id message) {
    NSArray<NSString *> *recordKeys = NeoWCSidePromptRecordKeys(message);
    if (recordKeys.count == 0) return nil;
    NSDictionary *records = [[NSUserDefaults standardUserDefaults] dictionaryForKey:NeoWCAntiRevokeSidePromptRecordsKey];
    BOOL matched = NO;
    for (NSString *recordKey in recordKeys) {
        if (records[recordKey]) { matched = YES; break; }
    }
    if (!matched) return nil;
    NSString *customText = [[NSUserDefaults standardUserDefaults] stringForKey:NeoWCAntiRevokeSideTextKey];
    return customText.length > 0 ? customText : @"已拦截撤回";
}

BOOL NeoWCAntiRevokeIsLocalPromptMessage(id message) {
    if (NeoWCUIntegerValue(message, @"m_uiMessageType") != 10000) return NO;
    NSString *content = NeoWCStringValue(message, @"m_nsContent");
    if (content.length == 0) return NO;
    NSArray<NSString *> *knownContents = [[NSUserDefaults standardUserDefaults] arrayForKey:NeoWCAntiRevokeLocalPromptContentsKey];
    return [knownContents containsObject:content];
}

static void NeoWCRememberLocalPromptContent(NSString *content) {
    if (content.length == 0) return;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray<NSString *> *knownContents = [[defaults arrayForKey:NeoWCAntiRevokeLocalPromptContentsKey] mutableCopy] ?: [NSMutableArray array];
    [knownContents removeObject:content];
    [knownContents insertObject:content atIndex:0];
    if (knownContents.count > 200) [knownContents removeObjectsInRange:NSMakeRange(200, knownContents.count - 200)];
    [defaults setObject:knownContents forKey:NeoWCAntiRevokeLocalPromptContentsKey];
}

static void NeoWCRememberSidePrompt(id message, NSString *text) {
    NSArray<NSString *> *recordKeys = NeoWCSidePromptRecordKeys(message);
    if (recordKeys.count == 0 || text.length == 0) return;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    @synchronized (defaults) {
        NSMutableDictionary *records = [[defaults dictionaryForKey:NeoWCAntiRevokeSidePromptRecordsKey] mutableCopy] ?: [NSMutableDictionary dictionary];
        while (records.count >= 800) [records removeObjectForKey:records.allKeys.firstObject];
        for (NSString *recordKey in recordKeys) records[recordKey] = text;
        [defaults setObject:records forKey:NeoWCAntiRevokeSidePromptRecordsKey];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
    });
}

static NSString *NeoWCTextBetween(NSString *text, NSString *opening, NSString *closing) {
    if (text.length == 0 || opening.length == 0 || closing.length == 0) return nil;
    NSRange first = [text rangeOfString:opening];
    if (first.location == NSNotFound) return nil;
    NSUInteger contentStart = NSMaxRange(first);
    if (contentStart > text.length) return nil;
    NSRange searchRange = NSMakeRange(contentStart, text.length - contentStart);
    NSRange last = [text rangeOfString:closing options:0 range:searchRange];
    if (last.location == NSNotFound) return nil;
    return [text substringWithRange:NSMakeRange(contentStart, last.location - contentStart)];
}

static NSDictionary<NSString *, NSString *> *NeoWCDateFields(NSDate *date) {
    NSCalendarUnit units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |
                           NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *parts = [[NSCalendar currentCalendar] components:units fromDate:date];
    return @{
        @"yyyy": [NSString stringWithFormat:@"%ld", (long)parts.year],
        @"MM": [NSString stringWithFormat:@"%02ld", (long)parts.month],
        @"dd": [NSString stringWithFormat:@"%02ld", (long)parts.day],
        @"HH": [NSString stringWithFormat:@"%02ld", (long)parts.hour],
        @"mm": [NSString stringWithFormat:@"%02ld", (long)parts.minute],
        @"ss": [NSString stringWithFormat:@"%02ld", (long)parts.second],
    };
}

static NSString *NeoWCMessageTypeName(NSUInteger type) {
    switch (type) {
        case 1:  return @"文本";
        case 3:  return @"图片";
        case 34: return @"语音";
        case 42: return @"名片";
        case 43: return @"视频";
        case 47: return @"表情";
        case 48: return @"位置";
        case 49: return @"分享";
        default: return [NSString stringWithFormat:@"类型(%lu)", (unsigned long)type];
    }
}

static NSString *NeoWCContentSummary(id message) {
    NSUInteger type = NeoWCUIntegerValue(message, @"m_uiMessageType");
    NSString *content = NeoWCStringValue(message, @"m_nsContent");
    if (type == 1 && content.length > 0) return content;
    return [NSString stringWithFormat:@"[%@]", NeoWCMessageTypeName(type)];
}

static NSString *NeoWCApplyRevokeTemplate(NSString *templateText,
                                          NSString *operatorName,
                                          NSString *contentSummary,
                                          NSDate *messageDate) {
    NSString *result = [templateText stringByReplacingOccurrencesOfString:@"{用户名}"
                                                                withString:operatorName ?: @"用户"];
    result = [result stringByReplacingOccurrencesOfString:@"{内容}"
                                                withString:contentSummary ?: @""];
    NSDictionary<NSString *, NSString *> *fields = NeoWCDateFields(messageDate ?: [NSDate date]);
    for (NSString *key in fields) {
        result = [result stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"{%@}", key]
                                                    withString:fields[key]];
    }
    return result;
}

static NSString *NeoWCRevokeOperatorName(NSString *replaceMessage) {
    NSRange phrase = [replaceMessage rangeOfString:@"撤回了一条消息"];
    NSString *name = phrase.location == NSNotFound ? @"用户" : [replaceMessage substringToIndex:phrase.location];
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (name.length >= 2 && [name hasPrefix:@"\""] && [name hasSuffix:@"\""]) {
        name = [name substringWithRange:NSMakeRange(1, name.length - 2)];
    }
    return name.length > 0 ? name : @"用户";
}

static id NeoWCNewMessageWrap(NSUInteger type) {
    Class wrapClass = objc_getClass("CMessageWrap");
    SEL initSelector = sel_registerName("initWithMsgType:");
    if (!wrapClass || ![wrapClass instancesRespondToSelector:initSelector]) return nil;
    id allocated = [wrapClass alloc];
    return ((id (*)(id, SEL, NSUInteger))objc_msgSend)(allocated, initSelector, type);
}

static id NeoWCSelfContact(void) {
    Class centerClass = objc_getClass("MMServiceCenter");
    Class contactManagerClass = objc_getClass("CContactMgr");
    if (!centerClass || !contactManagerClass) return nil;
    id center = ((id (*)(id, SEL))objc_msgSend)(centerClass, sel_registerName("defaultCenter"));
    if (!center) return nil;
    id contactManager = ((id (*)(id, SEL, Class))objc_msgSend)(center, sel_registerName("getService:"), contactManagerClass);
    if (!contactManager || ![contactManager respondsToSelector:sel_registerName("getSelfContact")]) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(contactManager, sel_registerName("getSelfContact"));
}

static id NeoWCOriginalMessage(id manager, NSString *session, long long serverID) {
    SEL selector = sel_registerName("GetMsg:n64SvrID:");
    if (!manager || ![manager respondsToSelector:selector]) return nil;
    return ((id (*)(id, SEL, NSString *, long long))objc_msgSend)(manager, selector, session, serverID);
}

static BOOL NeoWCInsertLocalMessage(id manager, NSString *session, id message) {
    SEL selector = sel_registerName("AddLocalMsg:MsgWrap:fixTime:NewMsgArriveNotify:");
    if (![manager respondsToSelector:selector]) return NO;
    ((void (*)(id, SEL, NSString *, id, BOOL, BOOL))objc_msgSend)(manager, selector, session, message, YES, NO);
    return YES;
}

static void NeoWCSendMessage(id manager, NSString *session, id message) {
    SEL selector = sel_registerName("AddMsg:MsgWrap:");
    if (![manager respondsToSelector:selector]) return;
    ((void (*)(id, SEL, NSString *, id))objc_msgSend)(manager, selector, session, message);
}

BOOL NeoWCHandleRevokeMessage(id messageManager, id incomingMessage) {
    if (!NeoWCEnhancementEnabled(NeoWCAntiRevokeKey) || !incomingMessage) return NO;

    NSString *xml = NeoWCStringValue(incomingMessage, @"m_nsContent");
    if (![xml containsString:@"<sysmsg type=\"revokemsg\"><revokemsg>"]) return NO;

    NSString *session = NeoWCTextBetween(xml, @"<session>", @"</session>");
    NSString *serverIDText = NeoWCTextBetween(xml, @"<newmsgid>", @"</newmsgid>");
    NSString *replaceMessage = NeoWCTextBetween(xml, @"<replacemsg><![CDATA[", @"]]></replacemsg>");
    long long serverID = serverIDText.longLongValue;
    if (session.length == 0 || serverID == 0 || replaceMessage.length == 0) return NO;

    // Own-message revoke notifications must keep WeChat's original behavior.
    if ([replaceMessage hasPrefix:@"你"] || [replaceMessage containsString:@"你撤回了一条消息"]) return NO;

    id selfContact = NeoWCSelfContact();
    NSString *selfUsername = NeoWCStringValue(selfContact, @"m_nsUsrName");
    if (selfUsername.length == 0) return NO;
    id original = NeoWCOriginalMessage(messageManager, session, serverID);
    NSString *originalFrom = NeoWCStringValue(original, @"m_nsFromUsr");
    if (!original || (selfUsername.length > 0 && [originalFrom isEqualToString:selfUsername])) return NO;

    NSString *operatorName = NeoWCRevokeOperatorName(replaceMessage);
    if ([operatorName isEqualToString:selfUsername]) return NO;
    NSUInteger createTime = NeoWCUIntegerValue(original, @"m_uiCreateTime");
    NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:createTime];
    NSString *summary = NeoWCContentSummary(original);
    NeoWCAntiRevokeAppendRecord(session, operatorName, original, summary, messageDate);

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *localTemplate = [defaults stringForKey:NeoWCAntiRevokeLocalTemplateKey];
    if (localTemplate.length == 0) localTemplate = NeoWCDefaultLocalRevokeTemplate;

    NSInteger promptStyle = [defaults integerForKey:NeoWCAntiRevokePromptStyleKey];
    if (promptStyle == 1) {
        NeoWCRememberSidePrompt(original, @"已拦截撤回");
    } else {
        id localMessage = NeoWCNewMessageWrap(10000);
        if (!localMessage) return NO;
        NeoWCSafeSetValue(localMessage, @"m_nsFromUsr", originalFrom);
        NeoWCSafeSetValue(localMessage, @"m_nsToUsr", NeoWCStringValue(original, @"m_nsToUsr"));
        NeoWCSafeSetValue(localMessage, @"m_uiStatus", @4);
        NSString *localPromptContent = NeoWCApplyRevokeTemplate(localTemplate, operatorName, summary, messageDate);
        NeoWCSafeSetValue(localMessage, @"m_nsContent", localPromptContent);
        NeoWCSafeSetValue(localMessage, @"m_uiCreateTime", @(createTime + 1));
        if (!NeoWCInsertLocalMessage(messageManager, session, localMessage)) return NO;
        NeoWCRememberLocalPromptContent(localPromptContent);
    }
    NeoWCLog(@"已拦截 %@ 的撤回消息：%@", operatorName, summary);

    if (![defaults boolForKey:NeoWCAntiRevokeNotifySenderKey]) return YES;
    NSTimeInterval filter = [defaults doubleForKey:NeoWCAntiRevokeTimeFilterKey];
    NSTimeInterval age = [NSDate date].timeIntervalSince1970 - createTime;
    if (filter > 0.0 && age > filter) return YES;

    NSString *replyTemplate = [defaults stringForKey:NeoWCAntiRevokeReplyTemplateKey];
    if (replyTemplate.length == 0) replyTemplate = NeoWCDefaultRevokeReplyTemplate;
    NSString *replyText = NeoWCApplyRevokeTemplate(replyTemplate, operatorName, summary, messageDate);
    id reply = NeoWCNewMessageWrap(1);
    if (!reply) return YES;
    NSString *target = [session containsString:@"@chatroom"] ? session : originalFrom;
    NeoWCSafeSetValue(reply, @"m_nsContent", replyText);
    NeoWCSafeSetValue(reply, @"m_nsFromUsr", selfUsername);
    NeoWCSafeSetValue(reply, @"m_nsToUsr", target);
    NeoWCSafeSetValue(reply, @"m_uiStatus", @4);
    NeoWCSafeSetValue(reply, @"m_uiCreateTime", @((NSUInteger)[NSDate date].timeIntervalSince1970));
    NeoWCSendMessage(messageManager, target, reply);
    NeoWCLog(@"已向撤回者发送提示（会话：%@）", target);
    return YES;
}

@interface NeoWCAntiRevokeRecordsViewController () <UISearchResultsUpdating>
@property (nonatomic, copy) NSArray<NSDictionary *> *visibleRecords;
@end

@implementation NeoWCAntiRevokeRecordsViewController

- (instancetype)init { return [self initWithStyle:UITableViewStyleInsetGrouped]; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"防撤回记录";
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    UISearchController *search = [[UISearchController alloc] initWithSearchResultsController:nil];
    search.searchResultsUpdater = self;
    search.obscuresBackgroundDuringPresentation = NO;
    search.searchBar.placeholder = @"搜索联系人或内容";
    self.navigationItem.searchController = search;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    [self reloadRecordsWithQuery:nil];
}

- (void)reloadRecordsWithQuery:(NSString *)query {
    NSArray *records;
    @synchronized (NeoWCAntiRevokeMemoryRecords()) { records = [NeoWCAntiRevokeMemoryRecords() copy]; }
    NSString *needle = [query stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (needle.length > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *record, __unused NSDictionary *bindings) {
            return [record[@"contact"] localizedCaseInsensitiveContainsString:needle] ||
                   [record[@"summary"] localizedCaseInsensitiveContainsString:needle] ||
                   [record[@"session"] localizedCaseInsensitiveContainsString:needle];
        }];
        records = [records filteredArrayUsingPredicate:predicate];
    }
    self.visibleRecords = records;
    [self.tableView reloadData];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self reloadRecordsWithQuery:searchController.searchBar.text];
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section { return self.visibleRecords.count; }

- (NSString *)tableView:(__unused UITableView *)tableView titleForFooterInSection:(__unused NSInteger)section {
    if (self.visibleRecords.count == 0) return @"本次运行尚未拦截撤回消息。默认记录只保存在内存中。";
    return [[NSUserDefaults standardUserDefaults] boolForKey:NeoWCAntiRevokePersistRecordsKey]
        ? @"已开启本地保存，仅保存消息摘要和类型，不复制媒体文件。"
        : @"记录仅在本次微信运行期间保存在内存中。";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"revoke-record"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"revoke-record"];
    NSDictionary *record = self.visibleRecords[indexPath.row];
    NSUInteger type = [record[@"type"] unsignedIntegerValue];
    NSString *category = type == 1 ? @"文字" : (type == 3 ? @"图片" : (type == 49 ? @"文件/分享" : NeoWCMessageTypeName(type)));
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[record[@"time"] doubleValue]];
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"MM-dd HH:mm:ss";
    cell.textLabel.text = [NSString stringWithFormat:@"%@ · %@", record[@"contact"], category];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  %@", [formatter stringFromDate:date], record[@"summary"]];
    cell.detailTextLabel.numberOfLines = 2;
    cell.imageView.image = [UIImage systemImageNamed:type == 3 ? @"photo" : (type == 1 ? @"text.bubble" : @"doc")];
    cell.imageView.tintColor = UIColor.secondaryLabelColor;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

@end

@interface NeoWCAntiRevokeAppearanceViewController () <UITextFieldDelegate, UIColorPickerViewControllerDelegate>
@property (nonatomic, strong) UIView *stage;
@property (nonatomic, strong) UIView *bubble;
@property (nonatomic, strong) UILabel *promptLabel;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UITextField *xField;
@property (nonatomic, strong) UITextField *yField;
@property (nonatomic, strong) UIButton *colorButton;
@property (nonatomic, strong) UILabel *coordinateLabel;
@property (nonatomic, assign) CGPoint panStart;
@end

@implementation NeoWCAntiRevokeAppearanceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"提示外观预览";
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    UIView *stage = [UIView new];
    stage.translatesAutoresizingMaskIntoConstraints = NO;
    stage.backgroundColor = [UIColor colorWithWhite:0.945 alpha:1.0];
    stage.layer.cornerRadius = 14.0;
    [self.view addSubview:stage];
    self.stage = stage;

    UIView *bubble = [UIView new];
    bubble.backgroundColor = [UIColor colorWithRed:0.58 green:0.91 blue:0.43 alpha:1.0];
    bubble.layer.cornerRadius = 7.0;
    [stage addSubview:bubble];
    self.bubble = bubble;
    UILabel *message = [[UILabel alloc] initWithFrame:CGRectMake(16.0, 0.0, 150.0, 54.0)];
    message.text = @"这是一条消息";
    message.font = [UIFont systemFontOfSize:16.0];
    [bubble addSubview:message];

    UILabel *prompt = [UILabel new];
    prompt.font = [UIFont systemFontOfSize:10.0];
    prompt.textColor = NeoWCColorForDefaultsKey(NeoWCAntiRevokeSideTextColorKey, UIColor.secondaryLabelColor);
    prompt.userInteractionEnabled = YES;
    prompt.text = [[NSUserDefaults standardUserDefaults] stringForKey:NeoWCAntiRevokeSideTextKey] ?: @"已拦截撤回";
    [prompt addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(promptPanned:)]];
    [stage addSubview:prompt];
    self.promptLabel = prompt;

    UITextField *field = [UITextField new];
    field.translatesAutoresizingMaskIntoConstraints = NO;
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.placeholder = @"提示文字";
    field.text = prompt.text;
    field.delegate = self;
    [field addTarget:self action:@selector(promptTextChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:field];
    self.textField = field;

    UIButton *colorButton = [UIButton buttonWithType:UIButtonTypeSystem];
    colorButton.translatesAutoresizingMaskIntoConstraints = NO;
    colorButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [colorButton setTitle:@"  提示文字颜色" forState:UIControlStateNormal];
    [colorButton setImage:[[UIImage systemImageNamed:@"circle.fill"] imageWithTintColor:prompt.textColor renderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [colorButton addTarget:self action:@selector(colorTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:colorButton];
    self.colorButton = colorButton;

    UILabel *coordinates = [UILabel new];
    coordinates.translatesAutoresizingMaskIntoConstraints = NO;
    coordinates.font = [UIFont monospacedDigitSystemFontOfSize:13.0 weight:UIFontWeightRegular];
    coordinates.textColor = UIColor.secondaryLabelColor;
    coordinates.text = @"拖动预览，或输入精确位置";
    [self.view addSubview:coordinates];
    self.coordinateLabel = coordinates;

    UITextField *(^coordinateField)(NSString *) = ^UITextField *(NSString *placeholder) {
        UITextField *input = [UITextField new];
        input.translatesAutoresizingMaskIntoConstraints = NO;
        input.borderStyle = UITextBorderStyleRoundedRect;
        input.placeholder = placeholder;
        input.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        input.textAlignment = NSTextAlignmentCenter;
        input.delegate = self;
        [input addTarget:self action:@selector(positionFieldChanged:) forControlEvents:UIControlEventEditingChanged];
        return input;
    };
    UITextField *xField = coordinateField(@"X");
    UITextField *yField = coordinateField(@"Y");
    [self.view addSubview:xField];
    [self.view addSubview:yField];
    self.xField = xField;
    self.yField = yField;

    UIButton *reset = [UIButton buttonWithType:UIButtonTypeSystem];
    reset.translatesAutoresizingMaskIntoConstraints = NO;
    [reset setTitle:@"恢复推荐位置 X 0 / Y 10" forState:UIControlStateNormal];
    [reset addTarget:self action:@selector(resetPosition) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:reset];

    [NSLayoutConstraint activateConstraints:@[
        [stage.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0],
        [stage.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0],
        [stage.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:24.0],
        [stage.heightAnchor constraintEqualToConstant:220.0],
        [field.leadingAnchor constraintEqualToAnchor:stage.leadingAnchor],
        [field.trailingAnchor constraintEqualToAnchor:stage.trailingAnchor],
        [field.topAnchor constraintEqualToAnchor:stage.bottomAnchor constant:20.0],
        [field.heightAnchor constraintEqualToConstant:44.0],
        [colorButton.leadingAnchor constraintEqualToAnchor:field.leadingAnchor],
        [colorButton.trailingAnchor constraintEqualToAnchor:field.trailingAnchor],
        [colorButton.topAnchor constraintEqualToAnchor:field.bottomAnchor constant:8.0],
        [colorButton.heightAnchor constraintEqualToConstant:40.0],
        [coordinates.leadingAnchor constraintEqualToAnchor:field.leadingAnchor],
        [coordinates.topAnchor constraintEqualToAnchor:colorButton.bottomAnchor constant:8.0],
        [xField.leadingAnchor constraintEqualToAnchor:field.leadingAnchor],
        [xField.topAnchor constraintEqualToAnchor:coordinates.bottomAnchor constant:8.0],
        [xField.heightAnchor constraintEqualToConstant:42.0],
        [yField.leadingAnchor constraintEqualToAnchor:xField.trailingAnchor constant:10.0],
        [yField.trailingAnchor constraintEqualToAnchor:field.trailingAnchor],
        [yField.topAnchor constraintEqualToAnchor:xField.topAnchor],
        [yField.widthAnchor constraintEqualToAnchor:xField.widthAnchor],
        [yField.heightAnchor constraintEqualToAnchor:xField.heightAnchor],
        [reset.trailingAnchor constraintEqualToAnchor:field.trailingAnchor],
        [reset.topAnchor constraintEqualToAnchor:xField.bottomAnchor constant:10.0],
    ]];
    [self layoutPrompt];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.bubble.frame = CGRectMake(CGRectGetWidth(self.stage.bounds) - 190.0, 72.0, 166.0, 54.0);
    [self layoutPrompt];
}

- (void)layoutPrompt {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    CGFloat x = [defaults objectForKey:NeoWCAntiRevokeSideOffsetXKey] ? [defaults doubleForKey:NeoWCAntiRevokeSideOffsetXKey] : 0.0;
    CGFloat y = [defaults objectForKey:NeoWCAntiRevokeSideOffsetYKey] ? [defaults doubleForKey:NeoWCAntiRevokeSideOffsetYKey] : 10.0;
    [self.promptLabel sizeToFit];
    self.promptLabel.center = CGPointMake(CGRectGetMinX(self.bubble.frame) - CGRectGetWidth(self.promptLabel.bounds) * 0.5 - 8.0 + x,
                                          CGRectGetMidY(self.bubble.frame) + y);
    self.coordinateLabel.text = [NSString stringWithFormat:@"当前位置  X %.0f  /  Y %.0f", x, y];
    if (!self.xField.isFirstResponder) self.xField.text = [NSString stringWithFormat:@"X  %.0f", x];
    if (!self.yField.isFirstResponder) self.yField.text = [NSString stringWithFormat:@"Y  %.0f", y];
}

- (void)promptPanned:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        self.panStart = CGPointMake([defaults doubleForKey:NeoWCAntiRevokeSideOffsetXKey], [defaults doubleForKey:NeoWCAntiRevokeSideOffsetYKey]);
    }
    CGPoint translation = [gesture translationInView:self.stage];
    CGFloat x = MIN(80.0, MAX(-80.0, self.panStart.x + translation.x));
    CGFloat y = MIN(80.0, MAX(-80.0, self.panStart.y + translation.y));
    [NSUserDefaults.standardUserDefaults setDouble:x forKey:NeoWCAntiRevokeSideOffsetXKey];
    [NSUserDefaults.standardUserDefaults setDouble:y forKey:NeoWCAntiRevokeSideOffsetYKey];
    [self layoutPrompt];
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [NSNotificationCenter.defaultCenter postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
    }
}

- (void)promptTextChanged:(UITextField *)field {
    NSString *text = field.text.length > 0 ? field.text : @"已拦截撤回";
    self.promptLabel.text = text;
    [NSUserDefaults.standardUserDefaults setObject:text forKey:NeoWCAntiRevokeSideTextKey];
    [self layoutPrompt];
}

- (void)positionFieldChanged:(UITextField *)field {
    NSString *numericText = [[field.text componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"-0123456789."] invertedSet]] componentsJoinedByString:@""];
    CGFloat value = MIN(80.0, MAX(-80.0, numericText.doubleValue));
    NSString *key = field == self.xField ? NeoWCAntiRevokeSideOffsetXKey : NeoWCAntiRevokeSideOffsetYKey;
    [NSUserDefaults.standardUserDefaults setDouble:value forKey:key];
    [self layoutPrompt];
}

- (void)colorTapped {
    UIColorPickerViewController *picker = [UIColorPickerViewController new];
    picker.title = @"气泡旁提示颜色";
    picker.selectedColor = self.promptLabel.textColor ?: UIColor.secondaryLabelColor;
    picker.supportsAlpha = YES;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)applySelectedPromptColor:(UIColor *)color {
    self.promptLabel.textColor = color;
    [self.colorButton setImage:[[UIImage systemImageNamed:@"circle.fill"] imageWithTintColor:color renderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [NSUserDefaults.standardUserDefaults setObject:NeoWCHexStringFromColor(color) forKey:NeoWCAntiRevokeSideTextColorKey];
}

- (void)colorPickerViewController:(__unused UIColorPickerViewController *)viewController didSelectColor:(UIColor *)color continuously:(__unused BOOL)continuously API_AVAILABLE(ios(15.0)) {
    [self applySelectedPromptColor:color];
}

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController {
    [self applySelectedPromptColor:viewController.selectedColor];
    [NSNotificationCenter.defaultCenter postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
}

- (void)resetPosition {
    [NSUserDefaults.standardUserDefaults setDouble:0.0 forKey:NeoWCAntiRevokeSideOffsetXKey];
    [NSUserDefaults.standardUserDefaults setDouble:10.0 forKey:NeoWCAntiRevokeSideOffsetYKey];
    [self layoutPrompt];
    [NSNotificationCenter.defaultCenter postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self layoutPrompt];
    [NSNotificationCenter.defaultCenter postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField != self.xField && textField != self.yField) return;
    NSString *key = textField == self.xField ? NeoWCAntiRevokeSideOffsetXKey : NeoWCAntiRevokeSideOffsetYKey;
    textField.text = [NSString stringWithFormat:@"%.0f", [NSUserDefaults.standardUserDefaults doubleForKey:key]];
    dispatch_async(dispatch_get_main_queue(), ^{ [textField selectAll:nil]; });
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField != self.xField && textField != self.yField) return;
    [self layoutPrompt];
    [NSNotificationCenter.defaultCenter postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [NSNotificationCenter.defaultCenter postNotificationName:NeoWCAntiRevokePromptDidChangeNotification object:nil];
}

@end
