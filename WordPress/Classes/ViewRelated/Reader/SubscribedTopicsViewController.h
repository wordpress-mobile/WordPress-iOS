#import <UIKit/UIKit.h>
#import "ReaderEditableSubscriptionPage.h"

typedef void (^TopicChanged)();

@interface SubscribedTopicsViewController : UIViewController<ReaderEditableSubscriptionPage>
@property (nonatomic, copy) TopicChanged topicChangedBlock;
@end
