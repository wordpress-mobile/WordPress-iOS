//
//  AbstractPost
//  WordPress
//
//  Created by Jorge Bernal on 12/27/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "AbstractPost.h"
#import "Media.h"
#import "ContextManager.h"

@implementation AbstractPost

@dynamic blog, media;
@dynamic comments;

- (void)remove {
    for (Media *media in self.media) {
        [media cancelUpload];
    }
	[super remove];
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
    
    if (!self.isDeleted && self.remoteStatus == AbstractPostRemoteStatusPushing) {
        // If we've just been fetched and our status is AbstractPostRemoteStatusPushing then something
        // when wrong saving -- the app crashed for instance. So change our remote status to failed.
        [self setPrimitiveValue:@(AbstractPostRemoteStatusFailed) forKey:@"remoteStatusNumber"];
    }
    
}

+ (NSString *const)remoteUniqueIdentifier {
    return @"";
}

- (void)markRemoteStatusFailed {
    self.remoteStatus = AbstractPostRemoteStatusFailed;
    [self save];
}

+ (AbstractPost *)newPostForBlog:(Blog *)blog {
    AbstractPost *post = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(self) inManagedObjectContext:blog.managedObjectContext];
    post.blog = blog;
    return post;
}

+ (AbstractPost *)newDraftForBlog:(Blog *)blog {
    AbstractPost *post = [self newPostForBlog:blog];
    post.remoteStatus = AbstractPostRemoteStatusLocal;
    post.status = @"publish";
    [post save];
    return post;
}

+ (NSArray *)existingPostsForBlog:(Blog *)blog inContext:(NSManagedObjectContext *)context {
    NSFetchRequest *existingFetch = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(self)];
    existingFetch.predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@) AND (postID != NULL) AND (original == NULL) AND (blog == %@)",
                               [NSNumber numberWithInt:AbstractPostRemoteStatusSync], blog];
    
    __block NSArray *existing = nil;
    [context performBlockAndWait:^{
        NSError *error;
        existing = [context executeFetchRequest:existingFetch error:&error];
        if (error) {
            DDLogError(@"Failed to fetch existing posts: %@", error);
            existing = nil;
        }
    }];

    return existing;
}

+ (void)mergeNewPosts:(NSArray *)newObjects forBlog:(Blog *)blog {
    NSManagedObjectContext *backgroundContext = [[ContextManager sharedInstance] backgroundContext];
    [backgroundContext performBlock:^{
        NSMutableArray *objectsToKeep = [NSMutableArray array];
        Blog *contextBlog = (Blog *)[backgroundContext existingObjectWithID:blog.objectID error:nil];
        
        NSArray *existingObjects = [self existingPostsForBlog:contextBlog inContext:backgroundContext];
        for (NSDictionary *newPost in newObjects) {
            NSNumber *postID = [[newPost objectForKey:[self remoteUniqueIdentifier]] numericValue];
            AbstractPost *post;
            
            NSArray *existingPostsWithPostId = [existingObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"postID == %@", postID]];
            if (existingPostsWithPostId && existingPostsWithPostId.count > 0) {
                post = existingPostsWithPostId[0];
            } else {
                post = [self newPostForBlog:contextBlog];
                post.postID = postID;
                post.remoteStatus = AbstractPostRemoteStatusSync;
            }
            [post updateFromDictionary:newPost];
            
            [objectsToKeep addObject:post];
        }
        
        NSArray *objectsToKeepIDs = [objectsToKeep valueForKey:@"objectID"];
        for (AbstractPost *post in existingObjects) {
            if (![objectsToKeepIDs containsObject:post.objectID] && post.objectID != nil) {
                if (post.revision) {
                    BOOL isPresent = NO;
                    
                    for (AbstractPost *p in objectsToKeep) {
                        if ([p.postID isEqual:post.postID]) {
                            isPresent = YES;
                            break;
                        }
                    }
                    
                    if (!isPresent) {
                        post.remoteStatus = AbstractPostRemoteStatusLocal;
                        post.postID = nil;
                        post.permaLink = nil;
                    }
                } else {
                    DDLogInfo(@"Deleting %@: %@", NSStringFromClass(self), post);
                    [backgroundContext deleteObject:post];
                }
            }
        }
        
        [[ContextManager sharedInstance] saveContext:backgroundContext];
    }];
}

- (void)updateFromDictionary:(NSDictionary *)postInfo {
    AssertSubclassMethod();
}

#pragma mark -
#pragma mark Revision management

- (void)cloneFrom:(AbstractPost *)source {
    for (NSString *key in [[[source entity] attributesByName] allKeys]) {
        if ([key isEqualToString:@"permalink"]) {
            DDLogInfo(@"Skipping %@", key);
        } else {
            DDLogInfo(@"Copying attribute %@", key);
            [self setValue:[source valueForKey:key] forKey:key];
        }
    }
    for (NSString *key in [[[source entity] relationshipsByName] allKeys]) {
        if ([key isEqualToString:@"original"] || [key isEqualToString:@"revision"]) {
            DDLogInfo(@"Skipping relationship %@", key);
        } else if ([key isEqualToString:@"comments"]) {
            DDLogInfo(@"Copying relationship %@", key);
            [self setComments:[source comments]];
        } else {
            DDLogInfo(@"Copying relationship %@", key);
            [self setValue: [source valueForKey:key] forKey: key];
        }
    }
}

- (AbstractPost *)createRevision {
    if ([self isRevision]) {
        DDLogInfo(@"!!! Attempted to create a revision of a revision");
        return self;
    }
    if (self.revision) {
        DDLogInfo(@"!!! Already have revision");
        return self.revision;
    }
	
    AbstractPost *post = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(self.class) inManagedObjectContext:self.managedObjectContext];
    [post cloneFrom:self];
    [post setValue:self forKey:@"original"];
    [post setValue:nil forKey:@"revision"];
    post.isFeaturedImageChanged = self.isFeaturedImageChanged;
    return post;
}

- (void)deleteRevision {
    if (self.revision) {
        [self.managedObjectContext performBlock:^{
            [self.managedObjectContext deleteObject:self.revision];
            [self setPrimitiveValue:nil forKey:@"revision"];
        }];
    }
}

- (void)applyRevision {
    if ([self isOriginal]) {
        [self cloneFrom:self.revision];
        self.isFeaturedImageChanged = self.revision.isFeaturedImageChanged;
    }
}

- (void)updateRevision {
    if ([self isRevision]) {
        [self cloneFrom:self.original];
        self.isFeaturedImageChanged = self.original.isFeaturedImageChanged;
    }
}

- (BOOL)isRevision {
    return (![self isOriginal]);
}

- (BOOL)isOriginal {
    return ([self original] == nil);
}

- (AbstractPost *)revision {
    return [self primitiveValueForKey:@"revision"];
}

- (AbstractPost *)original {
    return [self primitiveValueForKey:@"original"];
}

- (BOOL)hasChanged {
    if (![self isRevision])
        return NO;

    if ([self hasSiteSpecificChanges]) {
        return YES;
    }
    
    AbstractPost *original = (AbstractPost *)self.original;
    
    //first let's check if there's no post title or content (in case a cheeky user deleted them both)
    if ((self.postTitle == nil || [self.postTitle isEqualToString:@""]) && (self.content == nil || [self.content isEqualToString:@""]))
        return NO;
	
    // We need the extra check since [nil isEqual:nil] returns NO
    if ((self.postTitle != original.postTitle)
        && (![self.postTitle isEqual:original.postTitle]))
        return YES;
    
    if ((self.content != original.content)
        && (![self.content isEqual:original.content]))
        return YES;
	
    if ((self.status != original.status)
        && (![self.status isEqual:original.status]))
        return YES;
	
    if ((self.password != original.password)
        && (![self.password isEqual:original.password]))
        return YES;
	
    if ((self.dateCreated != original.dateCreated)
        && (![self.dateCreated isEqual:original.dateCreated]))
        return YES;
	
	if ((self.permaLink != original.permaLink)
        && (![self.permaLink  isEqual:original.permaLink]))
        return YES;
	
    if (self.hasRemote == NO) {
        return YES;
    }
    
    return NO;
}

- (BOOL)hasSiteSpecificChanges {
    if (![self isRevision]) {
        return NO;
    }
    
    AbstractPost *original = (AbstractPost *)self.original;
    
    //Do not move the Featured Image check below in the code.
    if ((self.post_thumbnail != original.post_thumbnail)
        && (![self.post_thumbnail  isEqual:original.post_thumbnail])){
        self.isFeaturedImageChanged = YES;
        return YES;
    } else {
        self.isFeaturedImageChanged = NO;
    }
    
    // Relationships are not going to be nil, just empty sets,
    // so we can avoid the extra check
    if (![self.media isEqual:original.media])
        return YES;
	
    return NO;
}

- (void)findComments {
    NSSet *comments = [self.blog.comments filteredSetUsingPredicate:
                       [NSPredicate predicateWithFormat:@"(postID == %@) AND (post == NULL)", self.postID]];
    if (comments && [comments count] > 0) {
        [self.comments unionSet:comments];
    }
}

@end
