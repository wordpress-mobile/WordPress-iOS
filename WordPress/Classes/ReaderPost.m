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

NSInteger const ReaderTopicEndpointIndex = 3;

@interface ReaderPost()

- (void)updateFromDictionary:(NSDictionary *)dict;
- (NSString *)createSummary:(NSString *)str;
- (NSDate *)convertDateString:(NSString *)dateString;
- (NSString *)normalizeParagraphs:(NSString *)string;

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
@dynamic sortDate;
@dynamic summary;
@dynamic comments;


+ (NSArray *)readerEndpoints {
	static NSArray *endpoints = nil;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		
		NSDictionary *fpDict = @{@"title": NSLocalizedString(@"Freshly Pressed", @""), @"endpoint":@"freshly-pressed", @"default":@YES};
		NSDictionary *follows = @{@"title": NSLocalizedString(@"Blogs I Follow", @""), @"endpoint":@"reader/following", @"default":@YES};
		NSDictionary *likes = @{@"title": NSLocalizedString(@"Blogs I Like", @""), @"endpoint":@"reader/liked", @"default":@YES};
		NSDictionary *topic = @{@"title": NSLocalizedString(@"Topics", @""), @"endpoint":@"reader/topics/%@", @"default":@NO};
		
		endpoints = @[fpDict, follows, likes, topic];
		
	});
	return endpoints;
}


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
	NSString *featuredImage = nil;

	// The results come in two flavors.  If editorial key, then its the freshly-pressed flavor.
	if ([dict objectForKey:@"editorial"]) {
		
		NSDictionary *editorial = [dict objectForKey:@"editorial"];

		author = [dict objectForKey:@"author"];
		
		self.author = [author objectForKey:@"name"];
		self.authorURL = [author objectForKey:@"URL"];

		self.blogName = [editorial objectForKey:@"blog_name"];
		
		self.content = [self normalizeParagraphs:[dict objectForKey:@"content"]];
		
		self.date_created_gmt = [self convertDateString:[dict objectForKey:@"date"]];
		self.sortDate = [self convertDateString:[editorial objectForKey:@"displayed_on"]];
		
		self.permaLink = [dict objectForKey:@"URL"];
		self.postTitle = [dict objectForKey:@"title"];
		
		NSURL *url = [NSURL URLWithString:self.permaLink];
		self.blogURL = [NSString stringWithFormat:@"%@://%@/", url.scheme, url.host];
		
		self.summary = [self createSummary:[dict objectForKey:@"content"]];
		
		NSString *img = [editorial objectForKey:@"image"];
		NSRange rng = [img rangeOfString:@"mshots/"];
		if(NSNotFound != rng.location) {
			img = [img stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			rng = [img rangeOfString:@"://" options:NSBackwardsSearch];
			rng.location += 3;
			rng.length = [img rangeOfString:@"?" options:NSBackwardsSearch].location - rng.location;
			img = [img substringWithRange:rng];
			
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
			
		} else {
			NSRange rng;
			rng.location = [img rangeOfString:@"://" options:NSBackwardsSearch].location + 3;
			img = [img substringFromIndex:rng.location];
		}
		featuredImage = img;

		
	} else {		
		author = [dict objectForKey:@"post_author"];
		
		self.author = [author objectForKey:@"post_author"];
		self.authorURL = [dict objectForKey:@"blog_url"];
		
		self.blogURL = [dict objectForKey:@"blog_url"];
		self.blogName = [dict objectForKey:@"blog_name"];

		self.content = [self normalizeParagraphs:[dict objectForKey:@"post_content_full"]];

		NSDate *date;
		NSString *timestamp = [dict objectForKey:@"post_timestamp"];
		if (timestamp != nil) {
			NSTimeInterval timeInterval = [timestamp doubleValue];
			date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
		} else {
			date = [self convertDateString:[dict objectForKey:@"post_date_gmt"]];
		}
		self.date_created_gmt = date;
		self.sortDate = date;
		
		self.permaLink = [dict objectForKey:@"post_permalink"];
		self.postTitle = [dict objectForKey:@"post_title"];
		
		self.summary = [self normalizeParagraphs:[dict objectForKey:@"post_content"]];
		
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

			featuredImage = [img substringWithRange:rng];
		}
		
		NSString *media = [dict objectForKey:@"post_featured_media"];
	
		if(media) {
			self.content = [NSString stringWithFormat:@"%@%@", media, self.content];
		}
	}

	self.authorAvatarURL = [author objectForKey:@"avatar_URL"];
	self.authorDisplayName = [author objectForKey:@"display_name"];
	// email can return a boolean.
	if([[author objectForKey:@"email"] isKindOfClass:[NSString class]]) {
		self.authorEmail = [author objectForKey:@"email"];
	}

    self.commentCount = [dict numberForKey:@"comment_count"];
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
	str = [self normalizeParagraphs:[str substringToIndex:300]];
	
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

	return [self normalizeParagraphs:snippet];
}


- (NSString *)normalizeParagraphs:(NSString *)string {
	NSError *error;
	
	// Convert div tags to p tags
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<div[^>]*>" options:NSRegularExpressionCaseInsensitive error:&error];
	string = [regex stringByReplacingMatchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, [string length]) withTemplate:@"<p>"];
	
	regex = [NSRegularExpression regularExpressionWithPattern:@"</div>" options:NSRegularExpressionCaseInsensitive error:&error];
	string = [regex stringByReplacingMatchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, [string length]) withTemplate:@"</p>"];
	
	// Remove duplicate p tags.
	regex = [NSRegularExpression regularExpressionWithPattern:@"<p[^>]*>\\s*<p[^>]*>" options:NSRegularExpressionCaseInsensitive error:&error];
	string = [regex stringByReplacingMatchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, [string length]) withTemplate:@"<p>"];
	
	regex = [NSRegularExpression regularExpressionWithPattern:@"</p>\\s*</p>" options:NSRegularExpressionCaseInsensitive error:&error];
	string = [regex stringByReplacingMatchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, [string length]) withTemplate:@"</p>"];
	return string;
}


- (NSDate *)convertDateString:(NSString *)dateString {
	
	NSArray *formats = @[@"yyyy-MM-dd'T'HH:mm:ssZZZZZ", @"yyyy-MM-dd HH:mm:ss"];
	NSDate *date;
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	
	for (NSString *dateFormat in formats) {
		[dateFormatter setDateFormat:dateFormat];
		date = [dateFormatter dateFromString:dateString];
		if(date){
			return date;
		}
	}
	
	return nil;
}


- (void)toggleLikedWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {

	BOOL oldValue = self.isLiked.boolValue;
	BOOL like = !oldValue;
	
	self.isLiked = [NSNumber numberWithBool:like];
	
	NSString *path = nil;
	if (like) {
		path = [NSString stringWithFormat:@"sites/%@/posts/%d/likes/new"];
	} else {
		path = [NSString stringWithFormat:@"sites/%@/posts/%d/likes/mine/delete"];
	}

	[[WordPressComApi sharedApi] postPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		[self save];
		
		if(success) {
			success();
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		// undo the change.
		self.isLiked = [NSNumber numberWithBool:oldValue];
		
		if(failure) {
			failure(error);
		}
	}];
}


- (void)toggleFollowingWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {

	BOOL oldValue = [self.isFollowing boolValue];
	BOOL follow = !oldValue;
		
	self.isFollowing = [NSNumber numberWithBool:follow];
	
	NSString *path = nil;
	if (follow) {
		path = [NSString stringWithFormat:@"sites/%@/follows/new"];
	} else {
		path = [NSString stringWithFormat:@"sites/%@/follows/mine/delete"];
	}
	
	[[WordPressComApi sharedApi] postPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		[self save];
		
		if(success) {
			success();
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		self.isFollowing = [NSNumber numberWithBool:oldValue];
		
		if(failure) {
			failure(error);
		}
	}];
}


- (void)reblogPostToSite:(id)newSite success:(void (^)())success failure:(void (^)(NSError *error))failure {
	return;
	NSString *path = [NSString stringWithFormat:@"sites/%@/posts/%d/reblogs/new"];
	[[WordPressComApi sharedApi] postPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		if(success) {
			success();
		}
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if(failure) {
			failure(error);
		}
	}];
}


@end
