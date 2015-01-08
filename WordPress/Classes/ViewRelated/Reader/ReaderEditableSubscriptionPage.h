#import <Foundation/Foundation.h>

// Pages can implement this protocol as a way of flagging they have editable content.
@protocol ReaderEditableSubscriptionPage <NSObject>
- (BOOL) isEditable;
@end
