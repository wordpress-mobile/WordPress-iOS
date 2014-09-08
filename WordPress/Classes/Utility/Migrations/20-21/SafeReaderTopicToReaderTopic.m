#import "SafeReaderTopicToReaderTopic.h"
#import "ReaderTopicService.h"
#import "ReaderTopic.h"

@interface SafeReaderTopicToReaderTopic()

@property (nonatomic, strong) NSString *topicPath;

@end


@implementation SafeReaderTopicToReaderTopic

- (BOOL)beginEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    ReaderTopicService *service = [[ReaderTopicService alloc] initWithManagedObjectContext:[manager sourceContext]];
    ReaderTopic *topic = [service currentTopic];
    self.topicPath = topic.path;

    return YES;
}

- (BOOL)endEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError *__autoreleasing *)error
{
    NSManagedObjectContext *context = [manager destinationContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([ReaderTopic class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"path = %@", self.topicPath];

    NSError *err;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&err];
    if (err) {
        DDLogError(@"Migration Error: Could not retrieve topic from destination context. %@", err);
    }

    ReaderTopicService *service = [[ReaderTopicService alloc] initWithManagedObjectContext:context];
    [service setCurrentTopic:[results firstObject]];

    return YES;
}

@end
