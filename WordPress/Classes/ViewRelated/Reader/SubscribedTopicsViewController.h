#import <UIKit/UIKit.h>
#import "ReaderEditableSubscriptionPage.h"

typedef void (^TopicListChanged)();

@interface SubscribedTopicsViewController : UIViewController<ReaderEditableSubscriptionPage>
@property (nonatomic, copy) TopicListChanged topicListChangedBlock;
@end
