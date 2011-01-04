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
- (void)updateLocalType;
- (void)cloneFrom:(AbstractPost *)source;
@end

@implementation AbstractPost
@dynamic author, content, dateCreated, postID, postTitle, status, localType;
@dynamic blog, media;

+ (NSString *)titleForStatus:(NSString *)status {
    if ([status isEqualToString:@"draft"]) {
        return @"Draft";
    } else if ([status isEqualToString:@"pending"]) {
        return @"Pending review";
    } else if ([status isEqualToString:@"private"]) {
        return @"Private";
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

- (BOOL)local {
    NSNumber *tmpValue;
    [self willAccessValueForKey:@"local"];
    tmpValue = [self primitiveValueForKey:@"local"];
    [self didAccessValueForKey:@"local"];
    return [tmpValue boolValue];
}

- (void)setLocal:(BOOL)value {
    [self willChangeValueForKey:@"local"];
    [self willChangeValueForKey:@"localType"];
    [self setPrimitiveValue:[NSNumber numberWithBool:value] forKey:@"local"];
    [self updateLocalType];
    [self didChangeValueForKey:@"localType"];
    [self didChangeValueForKey:@"local"];
}

- (BOOL)hasRemote {
    return ((self.postID != nil) && ([self.postID intValue] > 0));
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

- (AbstractPost *)newRevision {
    if ([self isRevision]) {
        NSLog(@"!!! Attempted to create a revision of a revision");
        return [self retain];
    }
    if (self.revision) {
        NSLog(@"!!! Already have revision");
        return [self.revision retain];
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

@end
