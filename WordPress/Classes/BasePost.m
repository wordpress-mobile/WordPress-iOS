//
//  BasePost.m
//  WordPress
//
//  Created by Eric J on 3/25/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "BasePost.h"
#import "Media.h"
#import "NSMutableDictionary+Helpers.h"

@interface BasePost(ProtectedMethods)
+ (NSString *)titleForStatus:(NSString *)status;
+ (NSString *)statusForTitle:(NSString *)title;
- (void)markRemoteStatusFailed;
@end

@implementation BasePost
@dynamic author, content, date_created_gmt, date_modified_gmt, postID, postTitle, status, password, remoteStatusNumber, 
		permaLink, mt_excerpt, mt_text_more, wp_slug, post_thumbnail;

@synthesize isFeaturedImageChanged, ignoreConflictCheck;

+ (NSString *)titleForStatus:(NSString *)status {
    if ([status isEqualToString:@"draft"]) {
        return NSLocalizedString(@"Draft", @"");
    } else if ([status isEqualToString:@"pending"]) {
        return NSLocalizedString(@"Pending review", @"");
    } else if ([status isEqualToString:@"private"]) {
        return NSLocalizedString(@"Privately published", @"");
    } else if ([status isEqualToString:@"publish"]) {
        return NSLocalizedString(@"Published", @"");
    } else {
        return status;
    }
}

+ (NSString *)statusForTitle:(NSString *)title {
    if ([title isEqualToString:NSLocalizedString(@"Draft", @"")]) {
        return @"draft";
    } else if ([title isEqualToString:NSLocalizedString(@"Pending review", @"")]) {
        return @"pending";
    } else if ([title isEqualToString:NSLocalizedString(@"Private", @"")]) {
        return @"private";
    } else if ([title isEqualToString:NSLocalizedString(@"Published", @"")]) {
        return @"publish";
    } else {
        return title;
    }
}

- (NSArray *)availableStatuses {
    return [NSArray arrayWithObjects:
            NSLocalizedString(@"Draft", @""),
            NSLocalizedString(@"Pending review", @""),
            NSLocalizedString(@"Private", @""),
            NSLocalizedString(@"Published", @""),
            nil];
}

- (BOOL)hasRemote {
    return ((self.postID != nil) && ([self.postID intValue] > 0));
}

- (void)remove {
    if (self.remoteStatus == AbstractPostRemoteStatusPushing || self.remoteStatus == AbstractPostRemoteStatusLocal) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUploadCancelled" object:self];
    }
    [[self managedObjectContext] deleteObject:self];
    [self save];
}

- (void)save {
    NSError *error;
    if (![[self managedObjectContext] save:&error]) {
        WPFLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
        exit(-1);
    }
}

- (NSString *)statusTitle {
    return [BasePost titleForStatus:self.status];
}

- (void)setStatusTitle:(NSString *)aTitle {
    self.status = [BasePost statusForTitle:aTitle];
}


- (BOOL)hasChanges {
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
            return NSLocalizedString(@"Uploading", @"");
            break;
        case AbstractPostRemoteStatusFailed:
            return NSLocalizedString(@"Failed", @"");
            break;
        case AbstractPostRemoteStatusConflicted:
            return NSLocalizedString(@"Conflicted", @"");
            break;
        case AbstractPostRemoteStatusSync:
            return NSLocalizedString(@"Posts", @"");
            break;
        default:
            return NSLocalizedString(@"Local", @"");
            break;
    }
}

- (NSString *)remoteStatusText {
    return [BasePost titleForRemoteStatus:self.remoteStatusNumber];
}

- (NSDate *)dateCreated {
	if(self.date_created_gmt != nil)
		return [DateUtils GMTDateTolocalDate:self.date_created_gmt];
	else 
		return nil;

}

- (void)setDateCreated:(NSDate *)localDate {
	if(localDate == nil)
		self.date_created_gmt = nil;
	else
		self.date_created_gmt = [DateUtils localDateToGMTDate:localDate];
}


- (void)findComments {
}

- (void)uploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
}

- (void)deletePostWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
}

- (void)getPostWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
}

- (NSDictionary *)XMLRPCDictionary {
    NSMutableDictionary *postParams = [NSMutableDictionary dictionary];

    [postParams setValueIfNotNil:self.postTitle forKey:@"post_title"];
    [postParams setValueIfNotNil:self.content forKey:@"post_content"];
    [postParams setValueIfNotNil:self.date_created_gmt forKey:@"post_date_gmt"];
    [postParams setValueIfNotNil:self.password forKey:@"post_password"];
    [postParams setValueIfNotNil:self.permaLink forKey:@"link"];
    [postParams setValueIfNotNil:self.mt_excerpt forKey:@"post_excerpt"];
    [postParams setValueIfNotNil:self.wp_slug forKey:@"post_name"];
    // To remove a featured image, you have to send an empty string to the API
    if (self.post_thumbnail == nil) {
        // Including an empty string for wp_post_thumbnail generates
        // an "Invalid attachment ID" error in the call to wp.newPage
        if ([self.postID longLongValue] > 0) {
            [postParams setValue:@"" forKey:@"post_thumbnail"];
        }

    } else {
        [postParams setValue:self.post_thumbnail forKey:@"post_thumbnail"];
	}

	if (self.mt_text_more != nil && [self.mt_text_more length] > 0)
        [postParams setObject:self.mt_text_more forKey:@"post_more"];

    return postParams;
}



@end
