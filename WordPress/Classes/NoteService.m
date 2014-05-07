#import "NoteService.h"
#import "ContextManager.h"
#import "Note.h"
#import "Blog.h"
#import "BlogService.h"


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
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Blog class])];
    fetchRequest.predicate = combinedPredicate;
    
    NSError *error = nil;
    NSArray *blogs = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        DDLogError(@"Error while retrieving blogs with stats: %@", error);
        return nil;
    }
    
    return [blogs firstObject];
}

@end
