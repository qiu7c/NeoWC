#import "NeoWCSettingsModels.h"

@implementation NeoWCSettingItem

+ (instancetype)itemWithIdentifier:(NSString *)identifier
                              title:(NSString *)title
                           subtitle:(NSString *)subtitle
                             symbol:(NSString *)symbol
                               kind:(NeoWCSettingRowKind)kind
                                key:(NSString *)key
                              value:(NSString *)value
                             action:(NeoWCSettingAction)action {
    NeoWCSettingItem *item = [self new];
    item.identifier = identifier;
    item.title = title;
    item.subtitle = subtitle;
    item.symbol = symbol;
    item.kind = kind;
    item.defaultsKey = key;
    item.value = value;
    item.action = action;
    return item;
}

@end

@implementation NeoWCSettingSection

+ (instancetype)sectionWithIdentifier:(NSString *)identifier
                                  title:(NSString *)title
                                 footer:(NSString *)footer
                                  items:(NSArray<NeoWCSettingItem *> *)items {
    NeoWCSettingSection *section = [self new];
    section.identifier = identifier;
    section.title = title;
    section.footer = footer;
    section.items = items;
    return section;
}

@end
