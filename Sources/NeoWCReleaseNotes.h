#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NeoWCReleaseNoteItem : NSObject
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *detail;
@property (nonatomic, copy, readonly) NSString *symbol;
+ (instancetype)itemWithTitle:(NSString *)title detail:(NSString *)detail symbol:(NSString *)symbol;
@end

@interface NeoWCReleaseNote : NSObject
@property (nonatomic, copy, readonly) NSString *version;
@property (nonatomic, copy, readonly) NSString *headline;
@property (nonatomic, copy, readonly) NSArray<NeoWCReleaseNoteItem *> *items;
+ (instancetype)noteWithVersion:(NSString *)version
                       headline:(NSString *)headline
                          items:(NSArray<NeoWCReleaseNoteItem *> *)items;
@end

FOUNDATION_EXPORT NSArray<NeoWCReleaseNote *> *NeoWCReleaseNotes(void);
FOUNDATION_EXPORT BOOL NeoWCShouldPresentCurrentReleaseNotes(void);
FOUNDATION_EXPORT void NeoWCMarkCurrentReleaseNotesPresented(void);

@interface NeoWCReleaseNotesViewController : UIViewController
@end

NS_ASSUME_NONNULL_END
