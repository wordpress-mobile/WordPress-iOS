#import "PublicizerService.h"
#import "Publicizer.h"
#import "Blog.h"
#import "ContextManager.h"
#import "RemotePublicizer.h"
#import "PublicizerServiceRemote.h"

@implementation PublicizerService

- (Publicizer *)newPublicizerForBlog:(Blog *)blog
{
    Publicizer *publicizer = [NSEntityDescription insertNewObjectForEntityForName:@"Publicizer"
                                                           inManagedObjectContext:self.managedObjectContext];
    publicizer.blog = blog;
    return publicizer;
}

- (Publicizer *)findWithBlogObjectID:(NSManagedObjectID *)blogObjectID andService:(NSString *)service;
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"service == %@", service];
    return [self findWithBlogObjectID:blogObjectID predicate:predicate];
}

- (Publicizer *)findWithBlogObjectID:(NSManagedObjectID *)blogObjectID predicate:(NSPredicate *)predicate
{
    Blog *blog = [self blogWithObjectID:blogObjectID];

    NSSet *results = [blog.publicizers filteredSetUsingPredicate:predicate];
    return [results anyObject];
}

- (void)syncPublicizersForBlog:(Blog *)blog
                       success:(void (^)())success
                       failure:(void (^)(NSError *error))failure
{
    PublicizerServiceRemote *remote = [[PublicizerServiceRemote alloc] initWithApi:blog.restApi];
    NSManagedObjectID *blogID = blog.objectID;
    [remote getPublicizersWithSuccess:^(NSArray *publicizers) {
                             [self.managedObjectContext performBlock:^{
                                 Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:blogID error:nil];
                                 if (!blog) {
                                     return;
                                 }
                                 [self mergePublicizers:publicizers forBlog:blog completionHandler:success];
                             }];
                         } failure:failure];
}


- (void)mergePublicizers:(NSArray *)publicizers forBlog:(Blog *)blog completionHandler:(void (^)(void))completion
{
    NSSet *remoteSet = [NSSet setWithArray:[publicizers valueForKey:@"service"]];
    NSSet *localSet = [blog.publicizers valueForKey:@"service"];
    NSMutableSet *toDelete = [localSet mutableCopy];
    [toDelete minusSet:remoteSet];

    if ([toDelete count] > 0) {
        for (Publicizer *publicizer in blog.publicizers) {
            if ([toDelete containsObject:publicizer.service]) {
                [self.managedObjectContext deleteObject:publicizer];
            }
        }
    }

    for (RemotePublicizer *remotePublicizer in publicizers) {
        Publicizer *publicizer = [self findWithBlogObjectID:blog.objectID andService:remotePublicizer.service];
        if (!publicizer) {
            publicizer = [self newPublicizerForBlog:blog];
            publicizer.service = remotePublicizer.service;
        }
        publicizer.label = remotePublicizer.label;
        publicizer.detail = remotePublicizer.detail;
        publicizer.icon = remotePublicizer.icon;
        publicizer.connect = remotePublicizer.connect;
    }
    
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

    if (completion) {
        completion();
    }
}

- (Blog *)blogWithObjectID:(NSManagedObjectID *)objectID
{
    if (objectID == nil) {
        return nil;
    }

    NSError *error;
    Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:objectID error:&error];
    if (error) {
        DDLogError(@"Error when retrieving Blog by ID: %@", error);
        return nil;
    }

    return blog;
}

@end
