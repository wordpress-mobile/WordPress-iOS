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

extern NSInteger const ReaderTopicEndpointIndex;

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
@property (nonatomic, strong) NSDate *sortDate;
@property (nonatomic, strong) NSString *summary;
@property (nonatomic, strong) NSMutableSet *comments;


/**
 An array of dictionaries representing available REST API endpoints to retrieve posts for the Reader.
 The dictionaries contain the endpoint title, API path fragment, and if the endpoint is one of the default topics.
 */
+ (NSArray *)readerEndpoints;


/**
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


/**
 Create or update an existing ReaderPost with the specified dictionary. 
 
 @param dict A dictionary representing the ReaderPost
 @param endpoint The endpoint from which the ReaderPost was retrieved. 
 @param context The Managed Object Context to fetch from. 
 */
+ (void)createOrUpdateWithDictionary:(NSDictionary *)dict forEndpoint:(NSString *)endpoint withContext:(NSManagedObjectContext *)context;



@end