//
//  AbstractPost
//  WordPress
//
//  Created by Jorge Bernal on 12/27/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "AbstractPost.h"
#import "Media.h"

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
    
    if (self.remoteStatus == AbstractPostRemoteStatusPushing) {
        // If we've just been fetched and our status is AbstractPostRemoteStatusPushing then something
        // when wrong saving -- the app crashed for instance. So change our remote status to failed.
        // Do this after a delay since property changes and saves are ignored during awakeFromFetch. See docs.
        [self performSelector:@selector(markRemoteStatusFailed) withObject:nil afterDelay:0.1];
    }
    
}

- (void)markRemoteStatusFailed {
    self.remoteStatus = AbstractPostRemoteStatusFailed;
    [self save];
}

#pragma mark -
#pragma mark Revision management

- (void)cloneFrom:(AbstractPost *)source {
    for (NSString *key in [[[source entity] attributesByName] allKeys]) {
        if ([key isEqualToString:@"permalink"]) {
            NSLog(@"Skipping %@", key);
        } else {
            NSLog(@"Copying attribute %@", key);
            [self setValue:[source valueForKey:key] forKey:key];
        }
    }
    for (NSString *key in [[[source entity] relationshipsByName] allKeys]) {
        if ([key isEqualToString:@"original"] || [key isEqualToString:@"revision"]) {
            NSLog(@"Skipping relationship %@", key);
        } else if ([key isEqualToString:@"comments"]) {
            NSLog(@"Copying relationship %@", key);
            [self setComments:[source comments]];
        } else {
            NSLog(@"Copying relationship %@", key);
            [self setValue: [source valueForKey:key] forKey: key];
        }
    }
}

- (AbstractPost *)createRevision {
    if ([self isRevision]) {
        NSLog(@"!!! Attempted to create a revision of a revision");
        return self;
    }
    if (self.revision) {
        NSLog(@"!!! Already have revision");
        return self.revision;
    }
	
    AbstractPost *post = [NSEntityDescription insertNewObjectForEntityForName:[[self entity] name] inManagedObjectContext:[self managedObjectContext]];
    [post cloneFrom:self];
    [post setValue:self forKey:@"original"];
    [post setValue:nil forKey:@"revision"];
    post.isFeaturedImageChanged = self.isFeaturedImageChanged;
    return post;
}

- (void)deleteRevision {
    if (self.revision) {
        [[self managedObjectContext] deleteObject:self.revision];
        [self setPrimitiveValue:nil forKey:@"revision"];
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
    return ([self primitiveValueForKey:@"original"] == nil);
}

- (AbstractPost *)revision {
    return [self primitiveValueForKey:@"revision"];
}

- (AbstractPost *)original {
    return [self primitiveValueForKey:@"original"];
}

- (BOOL)hasChanges {
    if (![self isRevision])
        return NO;
    
    //Do not move the Featured Image check below in the code.
    if ((self.post_thumbnail != self.original.post_thumbnail)
        && (![self.post_thumbnail  isEqual:self.original.post_thumbnail])){
        self.isFeaturedImageChanged = YES;
        return YES;
    } else
        self.isFeaturedImageChanged = NO;
	
    
    //first let's check if there's no post title or content (in case a cheeky user deleted them both)
    if ((self.postTitle == nil || [self.postTitle isEqualToString:@""]) && (self.content == nil || [self.content isEqualToString:@""]))
        return NO;
	
    // We need the extra check since [nil isEqual:nil] returns NO
    if ((self.postTitle != self.original.postTitle)
        && (![self.postTitle isEqual:self.original.postTitle]))
        return YES;
    if ((self.content != self.original.content)
        && (![self.content isEqual:self.original.content]))
        return YES;
	
    if ((self.status != self.original.status)
        && (![self.status isEqual:self.original.status]))
        return YES;
	
    if ((self.password != self.original.password)
        && (![self.password isEqual:self.original.password]))
        return YES;
	
    if ((self.dateCreated != self.original.dateCreated)
        && (![self.dateCreated isEqual:self.original.dateCreated]))
        return YES;
	
	if ((self.permaLink != self.original.permaLink)
        && (![self.permaLink  isEqual:self.original.permaLink]))
        return YES;
	
    if (self.hasRemote == NO) {
        return YES;
    }
    
    // Relationships are not going to be nil, just empty sets,
    // so we can avoid the extra check
    if (![self.media isEqual:self.original.media])
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

- (void)autosave {
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        // We better not crash on autosave
        WPFLog(@"[Autosave] Unresolved Core Data Save error %@, %@", error, [error userInfo]);
    }
}

@end
