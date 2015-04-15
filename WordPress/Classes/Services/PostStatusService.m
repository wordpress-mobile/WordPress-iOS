#import "PostStatusService.h"
#import "PostStatus.h"
#import "Blog.h"
#import "RemotePostStatus.h"
#import "ContextManager.h"
#import "PostStatusServiceRemote.h"
#import "PostStatusServiceRemoteREST.h"
#import "PostStatusServiceRemoteXMLRPC.h"

@interface PostStatusService ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation PostStatusService

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _managedObjectContext = context;
    }
    
    return self;
}

- (PostStatus *)newStatusForBlog:(Blog *)blog
{
    PostStatus *status = [NSEntityDescription insertNewObjectForEntityForName:@"Status"
                                                           inManagedObjectContext:self.managedObjectContext];
    status.blog = blog;
    return status;
}

- (void)syncStatusesForBlog:(Blog *)blog
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure
{
    id<PostStatusServiceRemote> remote = [self remoteForBlog:blog];
    [remote getStatusesForBlog:blog
                       success:^(NSArray *statuses) {
                           [self.managedObjectContext performBlock:^{
                               [self mergeStatuses:statuses forBlog:blog completionHandler:success];
                           }];
                       } failure:failure];
}

- (void)mergeStatuses:(NSArray *)statuses forBlog:(Blog *)blog completionHandler:(void (^)(void))completion
{
    // delete all statuses currently associated with blog as we can't track them by an id
    //// any of the status' properties could have changed since last merge
    for (PostStatus *status in blog.statuses) {
        [self.managedObjectContext deleteObject:status];
    }
    
    for (RemotePostStatus *remoteStatus in statuses) {
        PostStatus *status = [self newStatusForBlog:blog];
        status.name = remoteStatus.name;
        status.label = remoteStatus.label;
        status.isProtected = remoteStatus.isProtected;
        status.isPrivate = remoteStatus.isPrivate;
        status.isPublic = remoteStatus.isPublic;
    }
    
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    
    if (completion) {
        completion();
    }
}

- (id<PostStatusServiceRemote>)remoteForBlog:(Blog *)blog {
    if (blog.restApi) {
        return [[PostStatusServiceRemoteREST alloc] initWithApi:blog.restApi];
    } else {
        return [[PostStatusServiceRemoteXMLRPC alloc] initWithApi:blog.api];
    }
}

@end
