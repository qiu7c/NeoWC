#import <Foundation/Foundation.h>

typedef void (^NeoWCPaymentLinkCompletion)(NSString *title, NSError *error);

FOUNDATION_EXPORT BOOL NeoWCPaymentLinkMatchesRequest(NSURLRequest *request);
FOUNDATION_EXPORT void NeoWCPaymentLinkLearnFromRequest(NSURLRequest *request, NSData *uploadData);
FOUNDATION_EXPORT void NeoWCPaymentLinkLearnFromResponse(NSData *data);
FOUNDATION_EXPORT void NeoWCPaymentLinkLearnFromWAJSEvent(id event);
FOUNDATION_EXPORT BOOL NeoWCPaymentLinkIsTriggerText(NSString *text);
FOUNDATION_EXPORT NSString *NeoWCPaymentLinkSuggestedCardTitle(void);
FOUNDATION_EXPORT NSString *NeoWCPaymentLinkDisplayNumber(void);
FOUNDATION_EXPORT BOOL NeoWCPaymentLinkSetDisplayNumber(NSString *number);
FOUNDATION_EXPORT BOOL NeoWCPaymentLinkSend(NSString *cardTitle,
                                            NSString *identityUsername,
                                            NSString *targetUsername,
                                            NeoWCPaymentLinkCompletion completion);
