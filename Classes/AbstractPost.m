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

- (NSString *)statusTitle {
    return [AbstractPost titleForStatus:self.status];
}

- (void)setStatusTitle:(NSString *)aTitle {
    self.status = [AbstractPost statusForTitle:aTitle];
}

@end
