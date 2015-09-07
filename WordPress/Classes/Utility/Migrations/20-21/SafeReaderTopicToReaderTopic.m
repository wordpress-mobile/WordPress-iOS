#import "SafeReaderTopicToReaderTopic.h"
#import "ReaderTopicService.h"
#import "ReaderTopic.h"

NSString * const SavedTopicPathKey = @"SavedTopicPathKey";

@implementation SafeReaderTopicToReaderTopic

- (BOOL)beginEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    return YES;
}

- (BOOL)endEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError *__autoreleasing *)error
{
    return YES;
}

@end
