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
@dynamic lastSynced;
@dynamic path;
@dynamic posts;
@dynamic slug;
@dynamic title;
@dynamic topicDescription;
@dynamic topicID;
@dynamic type;

- (NSString *)titleForURL
{
    if ([self.slug length] > 0) {
        return self.slug;
    }

    // Fallback
    NSString *title = self.title;
    NSArray *components = [self.path componentsSeparatedByString:@"/"];
    if ([components count] > 2 && [[components lastObject] isEqualToString:@"posts"]) {
        title = [components objectAtIndex:[components count] - 2];
    }
    return title;
}

@end
