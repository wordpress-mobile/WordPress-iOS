//
//  BasePost.h
//  WordPress
//
//  Created by Eric J on 3/25/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Blog.h"
#import "DateUtils.h"
#import "WPContentViewProvider.h"

typedef enum {
    AbstractPostRemoteStatusPushing,    // Uploading post
    AbstractPostRemoteStatusFailed,      // Upload failed
    AbstractPostRemoteStatusLocal,       // Only local version
    AbstractPostRemoteStatusSync,       // Post uploaded
} AbstractPostRemoteStatus;

@interface BasePost : NSManagedObject<WPContentViewProvider> {

}

// Attributes
@property (nonatomic, strong) NSNumber * postID;
@property (nonatomic, strong) NSString * author;
@property (nonatomic, strong) NSDate * date_created_gmt;
@property (nonatomic, strong) NSString * postTitle;
@property (nonatomic, strong) NSString * content;
@property (nonatomic, strong) NSString * status;
@property (nonatomic, weak) NSString * statusTitle;
@property (nonatomic, strong) NSString * password;
@property (nonatomic, strong) NSString * permaLink;
@property (nonatomic, strong) NSString * mt_excerpt;
@property (nonatomic, strong) NSString * mt_text_more;
@property (nonatomic, strong) NSString * wp_slug;
@property (nonatomic, strong) NSNumber * remoteStatusNumber;
@property (nonatomic) AbstractPostRemoteStatus remoteStatus;
@property (nonatomic, strong) NSNumber * post_thumbnail;

@property (readonly) BOOL hasChanged;
@property (nonatomic, assign) BOOL isFeaturedImageChanged;

- (NSArray *)availableStatuses;
// Does the post exist on the blog?
- (BOOL)hasRemote;
// Deletes post locally
- (void)remove;
// Save changes to disk
- (void)save;

//date conversion
- (NSDate *)dateCreated;
- (void)setDateCreated:(NSDate *)localDate;

//comments
- (void)findComments;

// Subclass methods
- (NSString *)remoteStatusText;
+ (NSString *)titleForRemoteStatus:(NSNumber *)remoteStatus;

#pragma mark     Data Management
- (void)uploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)deletePostWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

@end
