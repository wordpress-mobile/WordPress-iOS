#import "SafeReaderTopicToReaderTopic.h"
#import "ReaderTopicService.h"
#import "ReaderTopic.h"

NSString * const SavedTopicPathKey = @"SavedTopicPathKey";

@implementation SafeReaderTopicToReaderTopic

- (BOOL)beginEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    ReaderTopicService *service = [[ReaderTopicService alloc] initWithManagedObjectContext:[manager sourceContext]];
    ReaderTopic *topic = [service currentTopic];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:topic.path forKey:SavedTopicPathKey];
    [defaults synchronize];

    return YES;
}

- (BOOL)endEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError *__autoreleasing *)error
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *topicPath = [defaults stringForKey:SavedTopicPathKey];
    [defaults removeObjectForKey:SavedTopicPathKey];
    [defaults synchronize];

    NSManagedObjectContext *context = [manager destinationContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([ReaderTopic class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"path = %@", topicPath];

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
