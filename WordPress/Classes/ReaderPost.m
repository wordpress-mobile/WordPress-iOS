//
//  ReaderPost.m
//  WordPress
//
//  Created by Eric J on 3/25/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderPost.h"
#import "WordPressComApi.h"

@interface ReaderPost()

- (void)updateFromDictionary:(NSDictionary *)dict;

@end

@implementation ReaderPost

@dynamic authorAvatarURL;
@dynamic authorDisplayName;
@dynamic authorEmail;
@dynamic authorURL;
@dynamic commentCount;
@dynamic dateSynced;
@dynamic endpoint;
@dynamic featuredImage;
@dynamic isFollowing;
@dynamic isLiked;
@dynamic isReblogged;
@dynamic likeCount;
@dynamic siteID;
@dynamic comments;


+ (NSArray *)fetchPostsForEndpoint:(NSString *)endpoint withContext:(NSManagedObjectContext *)context {

	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"ReaderPost" inManagedObjectContext:context]];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(endpoint = %@)", endpoint];
	[request setPredicate:predicate];
    
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    NSError *error = nil;
    NSArray *array = [context executeFetchRequest:request error:&error];
    if (array == nil) {
        array = [NSArray array];
    }
    return array;
}


+ (void)syncPostsFromEndpoint:(NSString *)endpoint withArray:(NSArray *)arr withContext:(NSManagedObjectContext *)context {
	
	[arr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[self createOrUpdateWithDictionary:obj forEndpoint:endpoint withContext:context];
	}];
	
    NSError *error;
    if(![context save:&error]){
        NSLog(@"Failed to sync ReaderPosts: %@", error);
    }
	
}


+ (void)deletePostsSynedEarlierThan:(NSDate *)syncedDate withContext:(NSManagedObjectContext *)context {

	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"ReaderPost" inManagedObjectContext:context]];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(dateSynced < %@)", syncedDate];
	[request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [context executeFetchRequest:request error:&error];

    if (array) {
        for (ReaderPost *post in array) {
            [context deleteObject:post];
        }
    }
    [context save:&error];
	
}


+ (void)createOrUpdateWithDictionary:(NSDictionary *)dict forEndpoint:(NSString *)endpoint withContext:(NSManagedObjectContext *)context {
	
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderPost"];
    request.predicate = [NSPredicate predicateWithFormat:@"(postID = %@) AND (endpoint = %@)", [dict objectForKey:@"ID"], endpoint];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date_created_gmt" ascending:YES]];
    request.fetchLimit = 1;
    
    NSError *error;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if(error != nil){
        NSLog(@"Error finding ReaderPost: %@", error);
        return;
    }
	
	ReaderPost *post;
    if ([results count] > 0) {
		post = (ReaderPost *)[results objectAtIndex:0];

    } else {
		post = (ReaderPost *)[NSEntityDescription insertNewObjectForEntityForName:@"ReaderPost"
														   inManagedObjectContext:context];
		post.postID = [dict objectForKey:@"ID"];
		post.endpoint = endpoint;
    }
    
    [post updateFromDictionary:dict];
	
}

- (void)updateFromDictionary:(NSDictionary *)dict {

	NSDictionary *author = [dict objectForKey:@"author"];
	self.author = [author objectForKey:@"name"];
	self.authorAvatarURL = [author objectForKey:@"avatar_URL"];
	self.authorDisplayName = [author objectForKey:@"display_name"];
	// email can return a boolean. 
	if([[author objectForKey:@"email"] isKindOfClass:[NSString class]]) {
		self.authorEmail = [author objectForKey:@"email"];
	}
	self.authorURL = [author objectForKey:@"URL"];
	
	if([[dict objectForKey:@"comment_count"] isKindOfClass:[NSNumber class]]){
		self.commentCount = [dict objectForKey:@"comment_count"];
	} else {
		self.commentCount = [NSNumber numberWithInteger:[[dict objectForKey:@"comment_count"] integerValue]];
	}
	self.content = [dict objectForKey:@"content"];
	
	NSString *dateString = nil;
	NSString *dateFormat = nil;
	if([dict objectForKey:@"date"]) {
		dateString = [dict objectForKey:@"date"];
		dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
	} else if ([dict objectForKey:@"post_date_gmt"]) {
		dateString = [dict objectForKey:@"post_date_gmt"];
		dateFormat = @"yyyy-MM-dd HH:mm:ss";
	} else {
		NSLog(@"!!!! UNKNOWN DATE KEY");
		NSLog(@"!!!! UNKNOWN DATE FORMAT");
	}
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:dateFormat];
	NSDate *date = [dateFormatter dateFromString:dateString];
	self.date_created_gmt = date;

	self.dateSynced = [NSDate date];
	self.featuredImage = [dict objectForKey:@"featured_image"];
	self.isFollowing = [dict objectForKey:@"is_following"];
	self.isLiked = [dict objectForKey:@"is_liked"];
	self.isReblogged = [dict objectForKey:@"is_reblogged"];
	self.likeCount = [dict objectForKey:@"like_count"];
	self.password = [dict objectForKey:@"password"];
	self.permaLink = [dict objectForKey:@"URL"];
	self.postTitle = [dict objectForKey:@"title"];
	self.siteID = [dict objectForKey:@"site_ID"];
	self.status = [dict objectForKey:@"status"];

}

@end
