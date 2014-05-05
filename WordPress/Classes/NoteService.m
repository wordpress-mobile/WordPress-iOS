#import "NoteService.h"
#import "ContextManager.h"
#import "Note.h"
#import "Blog.h"
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
    request.includesPendingChanges = NO;
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

- (Blog *)blogForStatsEventNote:(Note *)note
{
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.managedObjectContext];
    Blog *blog = [blogService blogByBlogId:note.metaSiteID];
    
    if (blog) {
        return blog;
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:note.subjectText];
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

@end
