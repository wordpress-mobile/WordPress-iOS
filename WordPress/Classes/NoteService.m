#import "NoteService.h"
#import "ContextManager.h"
#import "Note.h"
#import "Blog.h"
#import "NoteServiceRemote.h"
#import "AccountService.h"
#import "BlogService.h"

const NSUInteger NoteKeepCount = 20;

@interface NoteService ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation NoteService

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _managedObjectContext = context;
    }
    
    return self;
}

- (void)pruneOldNotesBefore:(NSNumber *)timestamp
{
    NSError *error;
    
    // For some strange reason, core data objects with changes are ignored when using fetchOffset
    // Even if you have 20 notes and fetchOffset is 20, any object with uncommitted changes would show up as a result
    // To avoid that we make sure to commit all changes before doing our request
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    
    NSUInteger keepCount = NoteKeepCount;
    if (timestamp) {
        NSFetchRequest *countRequest = [NSFetchRequest fetchRequestWithEntityName:@"Note"];
        countRequest.predicate = [NSPredicate predicateWithFormat:@"timestamp >= %@", timestamp];
        NSSortDescriptor *dateSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
        countRequest.sortDescriptors = @[ dateSortDescriptor ];
        NSError *error;
        NSUInteger notesCount = [self.managedObjectContext countForFetchRequest:countRequest error:&error];
        if (notesCount != NSNotFound) {
            keepCount = MAX(keepCount, notesCount);
        }
    }
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Note"];
    request.fetchOffset = keepCount;
    NSSortDescriptor *dateSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
    request.sortDescriptors = @[ dateSortDescriptor ];
    NSArray *notes = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"Error pruning old notes: %@", error);
        return;
    }
    
    for (Note *note in notes) {
        [self.managedObjectContext deleteObject:note];
    }
    
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
}

- (NSNumber *)lastNoteTimestamp
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Note"];
    request.resultType = NSDictionaryResultType;
    request.propertiesToFetch = @[@"timestamp"];
    request.fetchLimit = 1;
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:nil];
    NSNumber *timestamp;
    if ([results count]) {
        NSDictionary *note = results[0];
        timestamp = [note objectForKey:@"timestamp"];
    }
    return timestamp;
}

- (Blog *)blogForStatsEventNote:(Note *)note
{
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.managedObjectContext];
    Blog *blog = [blogService blogByBlogId:note.metaSiteID];
    
    if (blog) {
        return blog;
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:note.subject];
    NSString *blogName;
    
    while ([scanner isAtEnd] == NO) {
        [scanner scanUpToString:@"\"" intoString:NULL];
        [scanner scanString:@"\"" intoString:NULL];
        [scanner scanUpToString:@"\"" intoString:&blogName];
        [scanner scanString:@"\"" intoString:NULL];
    }
    
    if (blogName.length == 0) {
        return nil;
    }
    
    NSPredicate *subjectPredicate = [NSPredicate predicateWithFormat:@"self.blogName CONTAINS[cd] %@", blogName];
    NSPredicate *wpcomPredicate = [NSPredicate predicateWithFormat:@"self.account.isWpcom == YES"];
    NSPredicate *jetpackPredicate = [NSPredicate predicateWithFormat:@"self.jetpackAccount != nil"];
    NSPredicate *statsBlogsPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[wpcomPredicate, jetpackPredicate]];
    NSPredicate *combinedPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[subjectPredicate, statsBlogsPredicate]];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Blog"];
    fetchRequest.predicate = combinedPredicate;
    
    NSError *error = nil;
    NSArray *blogs = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        DDLogError(@"Error while retrieving blogs with stats: %@", error);
        return nil;
    }
    
    if (blogs.count > 0) {
        return [blogs firstObject];
    }
    
    return nil;
}

- (void)refreshUnreadNotes {
    NSFetchRequest *request = [[ContextManager sharedInstance].managedObjectModel fetchRequestTemplateForName:@"UnreadNotes"];
    NSError *error = nil;
    NSArray *notes = [self.managedObjectContext executeFetchRequest:request error:&error];
    if ([notes count] > 0) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:notes.count];
        for (Note *note in notes) {
            [array addObject:note.noteID];
        }
        
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
        WordPressComApi *api = [[accountService defaultWordPressComAccount] restApi];
        
        NoteServiceRemote *remote = [[NoteServiceRemote alloc] initWithRemoteApi:api];
        [remote refreshNotificationIds:array success:nil failure:nil];
    }
}

- (void)markNoteAsRead:(Note *)note success:(void (^)())success failure:(void (^)(NSError *))failure {
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    WordPressComApi *api = [[accountService defaultWordPressComAccount] restApi];
    NoteServiceRemote *remote = [[NoteServiceRemote alloc] initWithRemoteApi:api];
    
    [remote markNoteIdAsRead:note.noteID
                     success:^{
                         if (success) {
                             success();
                         }
                     } failure:^(NSError *error) {
                         if (failure) {
                             failure(error);
                         }
                     }];
}

@end
