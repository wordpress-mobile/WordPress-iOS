#import "ReaderTopic.h"
#import "ReaderSite.h"

NSString *const ReaderTopicTypeList = @"list";
NSString *const ReaderTopicTypeTag = @"tag";
NSString *const ReaderTopicTypeSite = @"site";

@implementation ReaderTopic

@dynamic account;
@dynamic isMenuItem;
@dynamic isRecommended;
@dynamic isSubscribed;
@dynamic isReadItLater;
@dynamic lastSynced;
@dynamic path;
@dynamic posts;
@dynamic title;
@dynamic topicDescription;
@dynamic topicID;
@dynamic type;

- (NSString *)titleForURL
{
    NSString *title = self.title;
    NSArray *components = [self.path componentsSeparatedByString:@"/"];
    if ([components count] > 2 && [[components lastObject] isEqualToString:@"posts"]) {
        title = [components objectAtIndex:[components count] - 2];
    }
    return title;
}

@end
