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
#import "NSString+XMLExtensions.h"

NSInteger const ReaderTopicEndpointIndex = 3;

@interface ReaderPost()

- (void)updateFromDictionary:(NSDictionary *)dict;
- (NSString *)createSummary:(NSString *)str;
- (NSString *)normalizeParagraphs:(NSString *)string;

@end

@implementation ReaderPost

@dynamic authorAvatarURL;
@dynamic authorDisplayName;
@dynamic authorEmail;
@dynamic authorURL;
@dynamic blogName;
@dynamic blogSiteID;
@dynamic blogURL;
@dynamic commentCount;
@dynamic commentsOpen;
@dynamic dateSynced;
@dynamic dateCommentsSynced;
@dynamic endpoint;
@dynamic featuredImage;
@dynamic isFollowing;
@dynamic isLiked;
@dynamic isReblogged;
@dynamic likeCount;
@dynamic postAvatar;
@dynamic siteID;
@dynamic sortDate;
@dynamic storedComment;
@dynamic summary;
@dynamic comments;


+ (NSArray *)readerEndpoints {
	static NSArray *endpoints = nil;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		
		NSDictionary *fpDict = @{@"title": NSLocalizedString(@"Freshly Pressed", @""), @"endpoint":@"freshly-pressed", @"default":@YES};
		NSDictionary *follows = @{@"title": NSLocalizedString(@"Blogs I Follow", @""), @"endpoint":@"reader/following", @"default":@YES};
		NSDictionary *likes = @{@"title": NSLocalizedString(@"Posts I Like", @""), @"endpoint":@"reader/liked", @"default":@YES};
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
	if (arr && [arr isKindOfClass:[NSArray class]]) {
        [arr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [self createOrUpdateWithDictionary:obj forEndpoint:endpoint withContext:context];
        }];

        NSError *error;
        if(![context save:&error]){
            NSLog(@"Failed to sync ReaderPosts: %@", error);
        }
    }
}


+ (void)deletePostsSynedEarlierThan:(NSDate *)syncedDate withContext:(NSManagedObjectContext *)context {

	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"ReaderPost" inManagedObjectContext:context]];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(dateSynced < %@)", syncedDate];
	[request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [context executeFetchRequest:request error:&error];

    if ([array count]) {
		NSLog(@"Deleting %i ReaderPosts synced earlier than: %@ ", [array count], syncedDate);
        for (ReaderPost *post in array) {
			NSLog(@"Post: %@", post);
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
		post.postID = [dict numberForKey:@"ID"];
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
		
		self.author = [author stringForKey:@"name"];
		self.authorURL = [author stringForKey:@"URL"];

		self.blogName = [editorial stringForKey:@"blog_name"];
		self.blogSiteID = [editorial numberForKey:@"site_id"];
		
		self.content = [self normalizeParagraphs:[dict objectForKey:@"content"]];
		self.commentsOpen = [dict numberForKey:@"comments_open"];
		
		self.date_created_gmt = [DateUtils dateFromISOString:[dict objectForKey:@"date"]];
		self.sortDate = [DateUtils dateFromISOString:[editorial objectForKey:@"displayed_on"]];
		self.likeCount = [dict numberForKey:@"like_count"];
		self.permaLink = [dict stringForKey:@"URL"];
		self.postTitle = [[dict stringForKey:@"title"] stringByDecodingXMLCharacters];
		
		self.isLiked = [dict numberForKey:@"i_like"];
		
		NSURL *url = [NSURL URLWithString:self.permaLink];
		self.blogURL = [NSString stringWithFormat:@"%@://%@/", url.scheme, url.host];
		
		self.siteID = [editorial numberForKey:@"blog_id"];

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
		if ([author isKindOfClass:[NSDictionary class]]) {
			self.author = [author stringForKey:@"post_author"];
		} else {
			// Some endpoints return a string and not an object
			self.author = [dict stringForKey:@"post_author"];
		}
		self.authorURL = [dict stringForKey:@"blog_url"];
		
		self.blogURL = [dict stringForKey:@"blog_url"];
		self.blogName = [dict stringForKey:@"blog_name"];
		self.blogSiteID = [dict numberForKey:@"blog_site_id"];

		self.content = [self normalizeParagraphs:[dict objectForKey:@"post_content_full"]];
		self.commentsOpen = [NSNumber numberWithBool:[@"open" isEqualToString:[dict stringForKey:@"comment_status"]]];
		
		NSDate *date;
		NSString *timestamp = [dict objectForKey:@"post_timestamp"];
		if (timestamp != nil) {
			NSTimeInterval timeInterval = [timestamp doubleValue];
			date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
		} else {
			date = [DateUtils dateFromISOString:[dict objectForKey:@"post_date_gmt"]];
		}
		self.date_created_gmt = date;
		self.sortDate = date;
		self.likeCount = [dict numberForKey:@"post_like_count"];
		self.permaLink = [dict stringForKey:@"post_permalink"];
		self.postTitle = [[dict stringForKey:@"post_title"] stringByDecodingXMLCharacters];
		
		self.isLiked = [dict numberForKey:@"is_liked"];
		
		self.siteID = [dict numberForKey:@"blog_id"];
		
		self.summary = [[[dict stringForKey:@"post_content"] stringByStrippingHTML] trim];
				
		NSString *img = [dict stringForKey:@"post_featured_thumbnail"];
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
		
		img = [dict stringForKey:@"post_avatar"];
		if ([img length]) {
			NSError *error;
			img = [img stringByDecodingXMLCharacters];
			NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"src=\"\\S+\"" options:NSRegularExpressionCaseInsensitive error:&error];
			NSRange rng = [regex rangeOfFirstMatchInString:img options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [img length])];

			if (NSNotFound != rng.location) {
				rng = NSMakeRange(rng.location+5, rng.length-6);
				self.postAvatar = [img substringWithRange:rng];
			}
		}
		
		NSString *media = [dict stringForKey:@"post_featured_media"];
	
		if(media) {
			self.content = [NSString stringWithFormat:@"%@%@", media, self.content];
		}
	}

	if([author isKindOfClass:[NSDictionary class]]) {
		self.authorAvatarURL = [author objectForKey:@"avatar_URL"];
		self.authorDisplayName = [author objectForKey:@"display_name"];
		// email can return a boolean.
		if([[author objectForKey:@"email"] isKindOfClass:[NSString class]]) {
			self.authorEmail = [author objectForKey:@"email"];
		}
	}
	
    self.commentCount = [dict numberForKey:@"comment_count"];
	self.dateSynced = [NSDate date];
	self.featuredImage = featuredImage;
	
	self.isFollowing = [dict numberForKey:@"is_following"];
	self.isReblogged = [dict numberForKey:@"is_reblogged"];

	self.status = [dict objectForKey:@"status"];

}


- (NSString *)createSummary:(NSString *)str {	
	str = [str stringByStrippingHTML];
	
	NSInteger idx = MIN(200, [str length]);
	NSString *snippet = [str substringToIndex:idx];
	NSRange rng = [snippet rangeOfString:@"." options:NSBackwardsSearch];
	
	if (rng.location == NSNotFound) {
		rng.location = MIN(150, [str length]);
	}
	
	if(rng.location > 150) {
		snippet = [snippet substringToIndex:(rng.location + 1)];
	} else {
		rng = [snippet rangeOfString:@" " options:NSBackwardsSearch];
		snippet = [NSString stringWithFormat:@"%@ ...", [snippet substringToIndex:rng.location]];
	}

	return [[self normalizeParagraphs:snippet] trim];
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
	
	// Remove inline styles.
	regex = [NSRegularExpression regularExpressionWithPattern:@"style=\".*\"" options:NSRegularExpressionCaseInsensitive error:&error];
	string = [regex stringByReplacingMatchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, [string length]) withTemplate:@""];
	
	return string;
}


- (void)toggleLikedWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {

	BOOL oldValue = self.isLiked.boolValue;
	BOOL like = !oldValue;
	NSNumber *oldCount = [self.likeCount copy];
	
	self.isLiked = [NSNumber numberWithBool:like];
	
	NSString *path = nil;
	if (like) {
		self.likeCount = [NSNumber numberWithInteger:([self.likeCount integerValue] + 1)];
		path = [NSString stringWithFormat:@"sites/%@/posts/%@/likes/new", self.siteID, self.postID];
	} else {
		self.likeCount = [NSNumber numberWithInteger:([self.likeCount integerValue] - 1)];
		path = [NSString stringWithFormat:@"sites/%@/posts/%@/likes/mine/delete", self.siteID, self.postID];
	}

	[[WordPressComApi sharedApi] postPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		[self save];
		
		if(success) {
			success();
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		// undo the change.
		self.isLiked = [NSNumber numberWithBool:oldValue];
		self.likeCount = oldCount;
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
		path = [NSString stringWithFormat:@"sites/%@/follows/new", self.siteID];
	} else {
		path = [NSString stringWithFormat:@"sites/%@/follows/mine/delete", self.siteID];
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


- (void)reblogPostToSite:(id)site note:(NSString *)note success:(void (^)())success failure:(void (^)(NSError *error))failure {
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:site forKey:@"destination_site_id"];
	
	if ([note length] > 0) {
		[params setObject:note forKey:@"note"];
	}

	NSString *path = [NSString stringWithFormat:@"sites/%@/posts/%@/reblogs/new", self.siteID, self.postID];
	[[WordPressComApi sharedApi] postPath:path parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		if(success) {
			success();
		}
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if(failure) {
			failure(error);
		}
	}];
}


- (NSString *)prettyDateString {
	NSDate *date = [self isFreshlyPressed] ? self.sortDate : self.dateCreated;
	NSString *str;
	NSTimeInterval diff = [[NSDate date] timeIntervalSince1970] - [date timeIntervalSince1970];
	
	if(diff < 60) {
		NSString *fmt = NSLocalizedString(@"%i second ago", @"second ago");
		if(diff == 1) {
			fmt = NSLocalizedString(@"%i seconds ago", @"seconds ago");
		}
		
		str = [NSString stringWithFormat:fmt, (NSInteger)diff];

	} else if(diff < 3600) {
		
		NSInteger min = (NSInteger)floor(diff / 60);
		NSInteger sec = (NSInteger)floor(fmod(diff, 60));
		NSString *minFmt = NSLocalizedString(@"%i minutes ago", @"minutes ago");
		NSString *secFmt = NSLocalizedString(@"%i seconds ago", @"seconds ago");
		if (min == 1) {
			minFmt = NSLocalizedString(@"%i minute ago", @"minute ago");
		}
		if (sec == 1) {
			secFmt = NSLocalizedString(@"%i second ago", @"second ago");
		}

		NSString *fmt = [NSString stringWithFormat:@"%@, %@", minFmt, secFmt];
		str = [NSString stringWithFormat:fmt, min, sec];
		
	} else if (diff < 86400) {
		
		NSInteger hr = (NSInteger)floor(diff / 3600);
		NSInteger min = (NSInteger)floor(fmod(diff, 3600) / 60);
		
		NSString *hrFmt = NSLocalizedString(@"%i hours ago", @"hours ago");
		NSString *minFmt = NSLocalizedString(@"%i minutes ago", @"minutes ago");
		if (hr == 1) {
			hrFmt = NSLocalizedString(@"%i hour ago", @"hour ago");
		}
		if (min == 1) {
			minFmt = NSLocalizedString(@"%i minute ago", @"minute ago");
		}
		
		NSString *fmt = [NSString stringWithFormat:@"%@, %@", hrFmt, minFmt];
		str = [NSString stringWithFormat:fmt, hr, min];
		
	} else {

		NSInteger day = (NSInteger)floor(diff / 86400);
		NSInteger hr = (NSInteger)floor(fmod(diff, 86400) / 3600);

		NSString *dayFmt = NSLocalizedString(@"%i days ago", @"days ago");
		NSString *hrFmt = NSLocalizedString(@"%i hours ago", @"hours ago");
		if (day == 1) {
			dayFmt = NSLocalizedString(@"%i day ago", @"day ago");
		}
		if (hr == 1) {
			hrFmt = NSLocalizedString(@"%i hour ago", @"hour ago");
		}
		
		NSString *fmt = [NSString stringWithFormat:@"%@, %@", dayFmt, hrFmt];
		str = [NSString stringWithFormat:fmt, day, hr];
		
	}
	
	return str;
}


- (BOOL)isFreshlyPressed {
	return ([self.endpoint rangeOfString:@"freshly-pressed"].location != NSNotFound)? true : false;
}


- (BOOL)isBlogsIFollow {
	return ([self.endpoint rangeOfString:@"reader/following"].location != NSNotFound)? true : false;
}


- (BOOL)isWPCom {
	return [self.blogSiteID integerValue] == 1 ? YES : NO;
}


- (void)storeComment:(NSNumber *)commentID comment:(NSString *)comment {
	self.storedComment = [NSString stringWithFormat:@"%i|storedcomment|%@", [commentID integerValue], comment];
}


- (NSDictionary *)getStoredComment {
	if (!self.storedComment) {
		return nil;
	}
	
	NSArray *arr = [self.storedComment componentsSeparatedByString:@"|storedcomment|"];
	NSNumber *commentID = [[arr objectAtIndex:0] numericValue];
	NSString *commentText = [arr objectAtIndex:1];
	return @{@"commentID":commentID, @"comment":commentText};
}


- (NSString *)avatar {
	return (self.postAvatar == nil) ? self.authorAvatarURL : self.postAvatar;
}


@end


@implementation ReaderPost (WordPressComApi)

+ (void)getReaderTopicsWithSuccess:(WordPressComApiRestSuccessResponseBlock)success
						   failure:(WordPressComApiRestSuccessFailureBlock)failure {
	
	NSString *path = @"reader/topics";
	
	[[WordPressComApi sharedApi] getPath:path parameters:nil success:success failure:failure];
}


+ (void)getCommentsForPost:(NSUInteger)postID
				  fromSite:(NSString *)siteID
			withParameters:(NSDictionary*)params
				   success:(WordPressComApiRestSuccessResponseBlock)success
				   failure:(WordPressComApiRestSuccessFailureBlock)failure {
	
	NSString *path = [NSString stringWithFormat:@"sites/%@/posts/%i/replies", siteID, postID];
	
	[[WordPressComApi sharedApi] getPath:path parameters:params success:success failure:failure];
}


+ (void)getPostsFromEndpoint:(NSString *)path
			  withParameters:(NSDictionary *)params
					 success:(WordPressComApiRestSuccessResponseBlock)success
					 failure:(WordPressComApiRestSuccessFailureBlock)failure {
	
	[[WordPressComApi sharedApi] getPath:path parameters:params success:success failure:failure];
}

@end