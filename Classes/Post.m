// 
//  Post.m
//  WordPress
//
//  Created by Chris Boyd on 8/9/10.
//

#import "Post.h"
#import "WPDataController.h"

@interface Post(PrivateMethods)
+ (Post *)newPostForBlog:(Blog *)blog;
- (void)uploadInBackground;
- (void)didUploadInBackground;
- (void)failedUploadInBackground;
@end

@implementation Post 

@dynamic geolocation, tags;
@dynamic categories, comments;

+ (Post *)newPostForBlog:(Blog *)blog {
    Post *post = [[Post alloc] initWithEntity:[NSEntityDescription entityForName:@"Post"
                                                          inManagedObjectContext:[blog managedObjectContext]]
               insertIntoManagedObjectContext:[blog managedObjectContext]];

    post.blog = blog;
    
    return post;
}

+ (Post *)newDraftForBlog:(Blog *)blog {
    Post *post = [self newPostForBlog:blog];
    post.remoteStatus = AbstractPostRemoteStatusLocal;
    post.status = @"publish";
    [post save];
    
    return post;
}

+ (Post *)findWithBlog:(Blog *)blog andPostID:(NSNumber *)postID {
    NSSet *results = [blog.posts filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"postID == %@ AND original == NULL",postID]];
    
    if (results && (results.count > 0)) {
        return [[results allObjects] objectAtIndex:0];
    }
    return nil;
}

+ (Post *)createOrReplaceFromDictionary:(NSDictionary *)postInfo forBlog:(Blog *)blog {
    Post *post = [self findWithBlog:blog andPostID:[[postInfo objectForKey:@"postid"] numericValue]];
    
    if (post == nil) {
        post = [[Post newPostForBlog:blog] autorelease];
    }
    
    post.postTitle      = [postInfo objectForKey:@"title"];
    post.postID         = [[postInfo objectForKey:@"postid"] numericValue];
    post.content        = [postInfo objectForKey:@"description"];
    post.dateCreated    = [postInfo objectForKey:@"dateCreated"];
    post.status         = [postInfo objectForKey:@"post_status"];
    post.password       = [postInfo objectForKey:@"wp_password"];
    post.tags           = [postInfo objectForKey:@"mt_keywords"];
    post.remoteStatus   = AbstractPostRemoteStatusSync;
    if ([postInfo objectForKey:@"categories"]) {
        [post setCategoriesFromNames:[postInfo objectForKey:@"categories"]];
    }
    
    return post;
}

- (void)remove {
    if ([self hasRemote] && [[WPDataController sharedInstance] mwDeletePost:self]) {
        [super remove];
    }
}

- (void)uploadInBackground {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if ([self hasRemote]) {
        if ([[WPDataController sharedInstance] mwEditPost:self]) {
            self.remoteStatus = AbstractPostRemoteStatusSync;
            [self performSelectorOnMainThread:@selector(didUploadInBackground) withObject:nil waitUntilDone:NO];
        } else {
            NSLog(@"Post update failed");
            self.remoteStatus = AbstractPostRemoteStatusFailed;
            [self performSelectorOnMainThread:@selector(failedUploadInBackground) withObject:nil waitUntilDone:NO];
        }
    } else {
        int postID = [[WPDataController sharedInstance] mwNewPost:self];
        if (postID == -1) {
            NSLog(@"Post upload failed");
            self.remoteStatus = AbstractPostRemoteStatusFailed;
            [self performSelectorOnMainThread:@selector(failedUploadInBackground) withObject:nil waitUntilDone:NO];
        } else {
            self.postID = [NSNumber numberWithInt:postID];
            self.remoteStatus = AbstractPostRemoteStatusSync;
            [self performSelectorOnMainThread:@selector(didUploadInBackground) withObject:nil waitUntilDone:NO];
        }
    }
    [self save];

    [pool release];
}

- (void)didUploadInBackground {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploaded" object:self];
}

- (void)failedUploadInBackground {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploadFailed" object:self];
}

- (void)upload {
    if ([self.password isEmpty])
        self.password = nil;

    [super upload];
    [self save];

    self.remoteStatus = AbstractPostRemoteStatusPushing;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self performSelectorInBackground:@selector(uploadInBackground) withObject:nil];
}

- (void)autosave {
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        // We better not crash on autosave
        NSLog(@"[Autosave] Unresolved Core Data Save error %@, %@", error, [error userInfo]);
        [FlurryAPI logError:@"Autosave" message:[error localizedDescription] error:error];
    }
}

- (NSString *)categoriesText {
    return [[[self.categories valueForKey:@"categoryName"] allObjects] componentsJoinedByString:@", "];
}

- (void)setCategoriesFromNames:(NSArray *)categoryNames {
    [self.categories removeAllObjects];
    for (NSString *categoryName in categoryNames) {
        NSSet *results = [self.blog.categories filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"categoryName like %@", categoryName]];
        if (results && (results.count > 0)) {
            self.categories = [NSMutableSet setWithSet:results];
        }
    }
}

- (BOOL)hasChanges {
    if ([super hasChanges]) return YES;

    if ((self.tags != ((Post *)self.original).tags)
        && (![self.tags isEqual:((Post *)self.original).tags]))
        return YES;

    if (![self.categories isEqual:((Post *)self.original).categories]) return YES;

    return NO;
}

@end
