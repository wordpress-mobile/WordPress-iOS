#import "ReaderTopic.h"

NSString *const ReaderTopicTypeList = @"list";
NSString *const ReaderTopicTypeTag = @"tag";

@implementation ReaderTopic

@dynamic isRecommended;
@dynamic isSubscribed;
@dynamic path;
@dynamic title;
@dynamic topicID;
@dynamic type;

@end
