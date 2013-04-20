//
//  ReaderPost.h
//  WordPress
//
//  Created by Eric J on 3/25/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BasePost.h"

@interface ReaderPost : BasePost

@property (nonatomic, strong) NSString *authorAvatarURL;
@property (nonatomic, strong) NSString *authorDisplayName;
@property (nonatomic, strong) NSString *authorEmail;
@property (nonatomic, strong) NSString *authorURL;
@property (nonatomic, strong) NSString *blogName;
@property (nonatomic, strong) NSString *blogURL;
@property (nonatomic, strong) NSNumber *commentCount;
@property (nonatomic, strong) NSDate *dateSynced;
@property (nonatomic, strong) NSString *endpoint;
@property (nonatomic, strong) NSString *featuredImage;
@property (nonatomic, strong) NSNumber *isFollowing;
@property (nonatomic, strong) NSNumber *isLiked;
@property (nonatomic, strong) NSNumber *isReblogged;
@property (nonatomic, strong) NSNumber *likeCount;
@property (nonatomic, strong) NSNumber *siteID;
@property (nonatomic, strong) NSString *summary;
@property (nonatomic, strong) NSMutableSet *comments;


/*
 Fetch posts for the specified endpoint. 
 
 @param endpoint REST endpoint that sourced the posts.
 @param context The managed object context to query.

 @return Returns an array of posts.
 */
+ (NSArray *)fetchPostsForEndpoint:(NSString *)endpoint withContext:(NSManagedObjectContext *)context;

/*
 Save or update posts for the specified endpoint.
 
 @param endpoint REST endpoint that sourced the posts.
 @param arr An array of dictionaries from which to build posts. 
 @param context The managed object context to query.
 
 @return Returns an array of posts.
 */
+ (void)syncPostsFromEndpoint:(NSString *)endpoint withArray:(NSArray *)arr withContext:(NSManagedObjectContext *)context;

/*
 Delete posts that were synced before the specified date.
 
 @param syncedDate The date before which posts should be deleted.
 @param context The managed object context to query.
 
 */
+ (void)deletePostsSynedEarlierThan:(NSDate *)syncedDate withContext:(NSManagedObjectContext *)context;


+ (void)createOrUpdateWithDictionary:(NSDictionary *)dict forEndpoint:(NSString *)endpoint withContext:(NSManagedObjectContext *)context;



@end