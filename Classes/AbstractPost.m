//
//  AbstractPost.m
//  WordPress
//
//  Created by Jorge Bernal on 12/27/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "AbstractPost.h"

@interface AbstractPost(ProtectedMethods)
+ (NSString *)titleForStatus:(NSString *)status;
+ (NSString *)statusForTitle:(NSString *)title;
- (void)cloneFrom:(AbstractPost *)source;
@end

@implementation AbstractPost
@dynamic author, content, dateCreated, postID, postTitle, status, password, remoteStatusNumber;
@dynamic blog, media;

+ (NSString *)titleForStatus:(NSString *)status {
    if ([status isEqualToString:@"draft"]) {
        return @"Draft";
    } else if ([status isEqualToString:@"pending"]) {
        return @"Pending review";
    } else if ([status isEqualToString:@"private"]) {
        return @"Privately published";
    } else if ([status isEqualToString:@"publish"]) {
        return @"Published";
    } else {
        return status;
    }
}

+ (NSString *)statusForTitle:(NSString *)title {
    if ([title isEqualToString:@"Draft"]) {
        return @"draft";
    } else if ([title isEqualToString:@"Pending review"]) {
        return @"pending";
    } else if ([title isEqualToString:@"Private"]) {
        return @"private";
    } else if ([title isEqualToString:@"Published"]) {
        return @"publish";
    } else {
        return title;
    }
}

- (NSArray *)availableStatuses {
    return [NSArray arrayWithObjects:
            @"Draft",
            @"Pending review",
            @"Private",
            @"Published",
            nil];
}

- (BOOL)hasRemote {
    return ((self.postID != nil) && ([self.postID intValue] > 0));
}

- (void)remove {
    [[self managedObjectContext] deleteObject:self];
}

- (void)save {
    NSError *error;
    if (![[self managedObjectContext] save:&error]) {
        NSLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
        exit(-1);
    }
}

- (NSString *)statusTitle {
    return [AbstractPost titleForStatus:self.status];
}

- (void)setStatusTitle:(NSString *)aTitle {
    self.status = [AbstractPost statusForTitle:aTitle];
}

#pragma mark -
#pragma mark Revision management
- (void)cloneFrom:(AbstractPost *)source {
    for (NSString *key in [[[source entity] attributesByName] allKeys]) {
        NSLog(@"Copying attribute %@", key);
        [self setValue:[source valueForKey:key] forKey:key];
    }
    for (NSString *key in [[[source entity] relationshipsByName] allKeys]) {
        if ([key isEqualToString:@"original"] || [key isEqualToString:@"revision"]) {
            NSLog(@"Skipping relationship %@", key);
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
        [self deleteRevision];
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

    // We need the extra check since [nil isEqual:nil] returns NO
    if ((self.postTitle != self.original.postTitle)
        && (![self.postTitle isEqual:self.original.postTitle]))
        return YES;

    if ((self.content != self.original.content)
        && (![self.content      isEqual:self.original.content]))
        return YES;

    if ((self.status != self.original.status)
        && (![self.status       isEqual:self.original.status]))
        return YES;

    if ((self.password != self.original.password)
        && (![self.password     isEqual:self.original.password]))
        return YES;

    if ((self.dateCreated != self.original.dateCreated)
        && (![self.dateCreated  isEqual:self.original.dateCreated]))
        return YES;

    // Relationships are not going to be nil, just empty sets,
    // so we can avoid the extra check
    if (![self.media isEqual:self.original.media])
        return YES;

    return NO;
}

- (AbstractPostRemoteStatus)remoteStatus {
    return (AbstractPostRemoteStatus)[[self remoteStatusNumber] intValue];
}

- (void)setRemoteStatus:(AbstractPostRemoteStatus)aStatus {
    [self setRemoteStatusNumber:[NSNumber numberWithInt:aStatus]];
}

- (void)upload {
}

+ (NSString *)titleForRemoteStatus:(NSNumber *)remoteStatus {
    switch ([remoteStatus intValue]) {
        case AbstractPostRemoteStatusPushing:
            return @"Uploading";
            break;
        case AbstractPostRemoteStatusFailed:
            return @"Failed";
            break;
        case AbstractPostRemoteStatusSync:
            return @"Posted";
            break;
        default:
            return @"Local";
            break;
    }
}

- (NSString *)remoteStatusText {
    return [AbstractPost titleForRemoteStatus:self.remoteStatusNumber];
}

@end
