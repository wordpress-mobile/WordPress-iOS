//
//  ReaderPost.m
//  WordPress
//
//  Created by Eric J on 3/25/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderPost.h"
#import "WordPressComApi.h"
#import "NSString+Helpers.h"
#import "NSString+Util.h"

@interface ReaderPost()

- (void)updateFromDictionary:(NSDictionary *)dict;
- (NSString *)createSummary:(NSString *)str;

@end

@implementation ReaderPost

@dynamic authorAvatarURL;
@dynamic authorDisplayName;
@dynamic authorEmail;
@dynamic authorURL;
@dynamic blogName;
@dynamic blogURL;
@dynamic commentCount;
@dynamic dateSynced;
@dynamic endpoint;
@dynamic featuredImage;
@dynamic isFollowing;
@dynamic isLiked;
@dynamic isReblogged;
@dynamic likeCount;
@dynamic siteID;
@dynamic summary;
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

	NSDictionary *author = nil;
	NSString *dateString = nil;
	NSString *dateFormat = nil;
	NSString *featuredImage = nil;
	
	// The results come in two flavors.  If editorial key, then freshly-pressed.
	if ([dict objectForKey:@"editorial"]) {
		
		NSDictionary *editorial = [dict objectForKey:@"editorial"];

		author = [dict objectForKey:@"author"];
		
		self.author = [author objectForKey:@"name"];
		self.authorURL = [author objectForKey:@"URL"];

		self.blogName = [editorial objectForKey:@"blog_name"];
		
		self.content = [dict objectForKey:@"content"];
		
		dateString = [dict objectForKey:@"date"];
		dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";

		self.permaLink = [dict objectForKey:@"URL"];
		self.postTitle = [dict objectForKey:@"title"];
		
		NSURL *url = [NSURL URLWithString:self.permaLink];
		self.blogURL = [NSString stringWithFormat:@"%@://%@/", url.scheme, url.host];
		
		self.summary = [self createSummary:[dict objectForKey:@"content"]];
		
		NSString *img = [editorial objectForKey:@"image"];
		
		if(NSNotFound != [img rangeOfString:@"mshots/"].location) {
			NSRange rng = [img rangeOfString:@"?" options:NSBackwardsSearch];
			img = [img substringToIndex:rng.location];
			img = [NSString stringWithFormat:@"%@?w=300&h=150", img];
			
		} else if(NSNotFound != [img rangeOfString:@"imgpress"].location) {
			NSRange rng;
			rng.location = [img rangeOfString:@"http" options:NSBackwardsSearch].location;
			rng.length = [img rangeOfString:@"&unsharp" options:NSBackwardsSearch].location - rng.location;
			img = [img substringWithRange:rng];

			// Actually decode twice.
			img = [img stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			img = [img stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

			rng = [img rangeOfString:@"://"];
			img = [img substringFromIndex:rng.location + 3];
			img = [NSString stringWithFormat:@"https://i0.wp.com/%@?w=300&h=150", img];
			
		} else {
			NSRange rng;
			rng.location = [img rangeOfString:@"://" options:NSBackwardsSearch].location + 3;
			img = [img substringFromIndex:rng.location];
			img = [NSString stringWithFormat:@"https://i0.wp.com/%@?w=300&h=150", img];
		}
		featuredImage = img;

		
	} else {		
		author = [dict objectForKey:@"post_author"];
		
		self.author = [author objectForKey:@"post_author"];
		self.authorURL = [dict objectForKey:@"blog_url"];
		
		self.blogURL = [dict objectForKey:@"blog_url"];
		self.blogName = [dict objectForKey:@"blog_name"];
		
		self.content = [dict objectForKey:@"post_content_full"];
		
		dateString = [dict objectForKey:@"post_date_gmt"];
		dateFormat = @"yyyy-MM-dd HH:mm:ss";
		
		self.permaLink = [dict objectForKey:@"post_permalink"];
		self.postTitle = [dict objectForKey:@"post_title"];
		
		self.summary = [dict objectForKey:@"post_content"];
		
		NSString *img = [dict objectForKey:@"post_featured_thumbnail"];
		if([img length]) {
			// TODO: Regex this madness
			NSRange rng = [img rangeOfString:@"://"];
			rng.location += 3;
			NSRange endRng = [img rangeOfString:@"?" options:NSBackwardsSearch];
			if(endRng.location == NSNotFound) {
				NSRange tmpRng;
				tmpRng.location = rng.location;
				tmpRng.length = [img length] - rng.location;
				endRng = [img rangeOfString:@"\"" options:nil range:tmpRng];
			}

			rng.length = endRng.location - rng.location;

			img = [img substringWithRange:rng];
			featuredImage = [NSString stringWithFormat:@"https://i0.wp.com/%@?w=300&h=150", img];
		}
	}

	self.authorAvatarURL = [author objectForKey:@"avatar_URL"];
	self.authorDisplayName = [author objectForKey:@"display_name"];
	// email can return a boolean.
	if([[author objectForKey:@"email"] isKindOfClass:[NSString class]]) {
		self.authorEmail = [author objectForKey:@"email"];
	}

	if([[dict objectForKey:@"comment_count"] isKindOfClass:[NSNumber class]]){
		self.commentCount = [dict objectForKey:@"comment_count"];
	} else {
		self.commentCount = [NSNumber numberWithInteger:[[dict objectForKey:@"comment_count"] integerValue]];
	}
		
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:dateFormat];
	NSDate *date = [dateFormatter dateFromString:dateString];
	self.date_created_gmt = date;

	self.dateSynced = [NSDate date];
	self.featuredImage = featuredImage;
	
	self.isFollowing = [dict objectForKey:@"is_following"];
	self.isLiked = [dict objectForKey:@"is_liked"];
	self.isReblogged = [dict objectForKey:@"is_reblogged"];
	self.likeCount = [dict objectForKey:@"like_count"];

	self.siteID = [dict objectForKey:@"site_ID"];
	self.status = [dict objectForKey:@"status"];

}


- (NSString *)createSummary:(NSString *)str {

	// TODO: strip out html.
	
	NSString *snippet = [str substringToIndex:200];
	NSRange rng = [snippet rangeOfString:@"." options:NSBackwardsSearch];
	
	if (rng.location == NSNotFound) {
		rng.location = 150;
	}
	
	if(rng.location > 150) {
		snippet = [snippet substringToIndex:(rng.location + 1)];
	} else {
		rng = [snippet rangeOfString:@" " options:NSBackwardsSearch];
		snippet = [NSString stringWithFormat:@"%@ ...", [snippet substringToIndex:rng.location]];
	}

	return snippet;
}


@end
