#import "ReaderTopic.h"

NSString *const ReaderTopicTypeList = @"list";
NSString *const ReaderTopicTypeTag = @"tag";

@implementation ReaderTopic

@dynamic account;
@dynamic isRecommended;
@dynamic isSubscribed;
@dynamic lastSynced;
@dynamic path;
@dynamic posts;
@dynamic title;
@dynamic topicID;
@dynamic type;

@end
