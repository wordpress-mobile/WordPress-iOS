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
#import "WPAvatarSource.h"
#import "NSString+Helpers.h"
#import "WordPressAppDelegate.h"

NSInteger const ReaderTopicEndpointIndex = 3;
NSInteger const ReaderPostSummaryLength = 150;
NSInteger const ReaderPostsToSync = 20;
NSString *const ReaderLastSyncDateKey = @"ReaderLastSyncDate";
NSString *const ReaderCurrentTopicKey = @"ReaderCurrentTopicKey";

@interface ReaderPost()

+ (void)handleLogoutNotification:(NSNotification *)notification;
- (void)updateFromDictionary:(NSDictionary *)dict;
- (void)updateFromRESTDictionary:(NSDictionary *)dict;
- (void)updateFromReaderDictionary:(NSDictionary *)dict;
- (NSString *)createSummary:(NSString *)str makePlainText:(BOOL)makePlainText;
- (NSString *)makePlainText:(NSString *)string;
- (NSString *)normalizeParagraphs:(NSString *)string;
- (NSString *)parseImageSrcFromHTML:(NSString *)html;

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

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLogoutNotification:) name:WordPressComApiDidLogoutNotification object:nil];
}


+ (void)handleLogoutNotification:(NSNotification *)notification {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ReaderLastSyncDateKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ReaderCurrentTopicKey];
	[NSUserDefaults resetStandardUserDefaults];
	
	NSManagedObjectContext *context = [[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext];
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderPost"];
    request.includesPropertyValues = NO;
    NSError *error;
    NSArray *posts = [context executeFetchRequest:request error:&error];
    if (posts) {
        for (ReaderPost *post in posts) {
            [context deleteObject:post];
        }
    }
    [context save:&error];
}


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


+ (NSDictionary *)currentTopic {
	NSDictionary *topic = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ReaderCurrentTopicKey];
	if(!topic) {
		topic = [[ReaderPost readerEndpoints] objectAtIndex:0];
	}
	return topic;
}


+ (NSString *)currentEndpoint {
	return [[self currentTopic] objectForKey:@"endpoint"];
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


+ (void)syncPostsFromEndpoint:(NSString *)endpoint withArray:(NSArray *)arr withContext:(NSManagedObjectContext *)context success:(void (^)())success {
    if (![arr isKindOfClass:[NSArray class]] || [arr count] == 0) {
		if (success) {
			dispatch_async(dispatch_get_main_queue(), success);
		}
        return;
    }
    NSManagedObjectContext *backgroundMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [backgroundMoc setParentContext:context];
	
    [backgroundMoc performBlock:^{
        NSError *error;
        for (NSDictionary *postData in arr) {
            if (![postData isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            [self createOrUpdateWithDictionary:postData forEndpoint:endpoint withContext:backgroundMoc];
			
        }
		
        if(![backgroundMoc save:&error]){
            WPFLog(@"Failed to sync ReaderPosts: %@", error);
        }
        [context performBlock:^{
            NSError *error;
            if (![context save:&error]) {
                WPFLog(@"Failed to sync ReaderPosts: %@", error);
            }
        }];
		
		if (success) {
			dispatch_async(dispatch_get_main_queue(), success);
		}
    }];
}


+ (void)deletePostsSyncedEarlierThan:(NSDate *)syncedDate withContext:(NSManagedObjectContext *)context {

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
    
    @autoreleasepool {
        [post updateFromDictionary:dict];
    }
}


- (void)updateFromDictionary:(NSDictionary *)dict {
	// The results come in two flavors.  If post_content_full then its the "reader" api, otherwise its the REST api.
	if (![dict objectForKey:@"post_content_full"]) {
		// REST feeds: fresly-pressed, sites/site/posts
		[self updateFromRESTDictionary:dict];
		
	} else {
		// "Reader" feeds: following, liked, and topics.
		[self updateFromReaderDictionary:dict];
	}

    self.commentCount = [dict numberForKey:@"comment_count"];
	self.isFollowing = [dict numberForKey:@"is_following"];
	self.isReblogged = [dict numberForKey:@"is_reblogged"];
	self.status = [dict objectForKey:@"status"];

	self.dateSynced = [NSDate date];
}


- (void)updateFromRESTDictionary:(NSDictionary *)dict {
	// REST api.  Freshly Pressed, sites/site/posts
	
	// Freshly Pressed posts will have an editorial section.
	NSDictionary *editorial = [dict objectForKey:@"editorial"];
	if (editorial) {
		self.blogName = [[editorial stringForKey:@"blog_name"] stringByDecodingXMLCharacters];
		self.blogSiteID = [editorial numberForKey:@"site_id"];
		self.siteID = [editorial numberForKey:@"blog_id"];
		self.sortDate = [DateUtils dateFromISOString:[editorial objectForKey:@"displayed_on"]];
		
		NSString *img = [editorial stringForKey:@"image"];
		NSRange rng = [img rangeOfString:@"mshots/"];
		if(NSNotFound != rng.location) {
			rng = [img rangeOfString:@"?" options:NSBackwardsSearch];
			img = [img substringWithRange:NSMakeRange(0, rng.location)]; // Just strip the query string off the end and we'll specify it later.
			
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
		self.featuredImage = img;
		
	} else {
		self.blogName = [[dict stringForKey:@"blog_name"] stringByDecodingXMLCharacters];
		self.blogSiteID = [dict numberForKey:@"site_id"];
		self.siteID = [dict numberForKey:@"blog_id"];
		self.sortDate = [DateUtils dateFromISOString:[dict objectForKey:@"date"]];
	}
	
	NSDictionary *author = [dict objectForKey:@"author"];
	self.author = [author stringForKey:@"name"];
	self.authorURL = [author stringForKey:@"URL"];
	self.authorAvatarURL = [author stringForKey:@"avatar_URL"];
	// email can return a boolean.
	if([[author objectForKey:@"email"] isKindOfClass:[NSString class]]) {
		self.authorEmail = [author stringForKey:@"email"];
	}
	
	
	self.content = [self normalizeParagraphs:[dict objectForKey:@"content"]];
	self.commentsOpen = [dict numberForKey:@"comments_open"];
	
	self.date_created_gmt = [DateUtils dateFromISOString:[dict objectForKey:@"date"]];
	
	self.likeCount = [dict numberForKey:@"like_count"];
	self.permaLink = [dict stringForKey:@"URL"];
	self.postTitle = [[[dict stringForKey:@"title"] stringByDecodingXMLCharacters] trim];
	
	self.isLiked = [dict numberForKey:@"i_like"];
	
	NSURL *url = [NSURL URLWithString:self.permaLink];
	self.blogURL = [NSString stringWithFormat:@"%@://%@/", url.scheme, url.host];
	
	self.summary = [self createSummary:[dict objectForKey:@"content"] makePlainText:YES];
}


- (void)updateFromReaderDictionary:(NSDictionary *)dict {
	
	NSDictionary *author = [dict objectForKey:@"post_author"];
	if ([author isKindOfClass:[NSDictionary class]]) {
		self.author = [author stringForKey:@"post_author"];
		self.authorAvatarURL = [author stringForKey:@"avatar_URL"];
		self.authorDisplayName = [author stringForKey:@"display_name"];
		// email can return a boolean.
		if([[author objectForKey:@"email"] isKindOfClass:[NSString class]]) {
			self.authorEmail = [author stringForKey:@"email"];
		}
		
	} else {
		// Some endpoints return a string and not an object
		self.author = [dict stringForKey:@"post_author"];
	}
	self.authorURL = [dict stringForKey:@"blog_url"];
	
	self.blogURL = [dict stringForKey:@"blog_url"];
	self.blogName = [[dict stringForKey:@"blog_name"] stringByDecodingXMLCharacters];
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
	self.postTitle = [[[dict stringForKey:@"post_title"] stringByDecodingXMLCharacters] trim];
	
	self.isLiked = [dict numberForKey:@"is_liked"];
	
	self.siteID = [dict numberForKey:@"blog_id"];
	
	NSString *summary = [self makePlainText:[dict stringForKey:@"post_content"]];
	if ([summary length] > ReaderPostSummaryLength) {
		summary = [self createSummary:summary makePlainText:NO];
	}
	self.summary = summary;
	
	NSString *img = [dict stringForKey:@"post_featured_thumbnail"];
	if (![img length]) {
		img = [dict stringForKey:@"post_featured_media"];
	}
	if([img length]) {
		if (NSNotFound != [img rangeOfString:@"<img "].location) {
			self.featuredImage = [self parseImageSrcFromHTML:img];
		}
	}
	
	img = [dict stringForKey:@"post_avatar"];
	if ([img length]) {
		img = [img stringByDecodingXMLCharacters];
		self.postAvatar = [self parseImageSrcFromHTML:img];
	}
}


- (NSString *)parseImageSrcFromHTML:(NSString *)html {
	NSError *error;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"src=\"\\S+\"" options:NSRegularExpressionCaseInsensitive error:&error];
	NSRange rng = [regex rangeOfFirstMatchInString:html options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [html length])];
	
	if (NSNotFound != rng.location) {
		rng = NSMakeRange(rng.location+5, rng.length-6);
		return [html substringWithRange:rng];
	}
	return nil;
}


- (NSString *)makePlainText:(NSString *)string {
	return [[[string stringByStrippingHTML] stringByDecodingXMLCharacters] trim];
}


- (NSString *)createSummary:(NSString *)str makePlainText:(BOOL)makePlainText {
	if (makePlainText) {
		str = [self makePlainText:str];
	}
	
	str = [str stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]];
	
	NSInteger idx = MIN(200, [str length]);
	NSString *snippet = [str substringToIndex:idx];
	NSRange rng = [snippet rangeOfString:@"." options:NSBackwardsSearch];
	
	if (rng.location == NSNotFound) {
		rng.location = MIN(ReaderPostSummaryLength, [str length]);
	}
	
	if(rng.location > ReaderPostSummaryLength) {
		snippet = [snippet substringToIndex:(rng.location + 1)];
	} else {
		rng = [snippet rangeOfString:@" " options:NSBackwardsSearch];
		if (rng.location != NSNotFound) {
			snippet = [NSString stringWithFormat:@"%@ ...", [snippet substringToIndex:rng.location]];
		}
	}

	return snippet;
}


- (NSString *)normalizeParagraphs:(NSString *)string {

	if (!string) {
		return @"";
	}
	
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
	regex = [NSRegularExpression regularExpressionWithPattern:@"style=\"[^\"]*\"" options:NSRegularExpressionCaseInsensitive error:&error];
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
		NSDictionary *dict = (NSDictionary *)responseObject;
		self.isReblogged = [dict numberForKey:@"is_reblogged"];

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
	NSDate *date = [self isFreshlyPressed] ? self.sortDate : self.date_created_gmt;
	NSString *str;
	NSTimeInterval diff = [[NSDate date] timeIntervalSinceDate:date];
	
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

- (UIImage *)cachedAvatarWithSize:(CGSize)size {
    NSString *hash;
    WPAvatarSourceType type = [self avatarSourceTypeWithHash:&hash];
    if (!hash) {
        return nil;
    }
    return [[WPAvatarSource sharedSource] cachedImageForAvatarHash:hash ofType:type withSize:size];
}

- (void)fetchAvatarWithSize:(CGSize)size success:(void (^)(UIImage *image))success {
    NSString *hash;
    WPAvatarSourceType type = [self avatarSourceTypeWithHash:&hash];

    if (hash) {
        [[WPAvatarSource sharedSource] fetchImageForAvatarHash:hash ofType:type withSize:size success:success];
    } else if (success) {
        success(nil);
    }
}

- (WPAvatarSourceType)avatarSourceTypeWithHash:(NSString **)hash {
    NSString *url = self.postAvatar ? self.postAvatar : self.authorAvatarURL;
    if (url) {
        NSURL *avatarURL = [NSURL URLWithString:url];
        if (avatarURL) {
            return [[WPAvatarSource sharedSource] parseURL:avatarURL forAvatarHash:hash];
        }
    }
    if (self.blogURL) {
        *hash = [[[NSURL URLWithString:self.blogURL] host] md5];
        return WPAvatarSourceTypeBlavatar;
    }
    return WPAvatarSourceTypeUnknown;
}

- (NSURL *)featuredImageURL {
    // FIXME: NSURL fails if the URL contains spaces.
    return [NSURL URLWithString:self.featuredImage];
}

- (NSString *)featuredImageForWidth:(NSUInteger)width height:(NSUInteger)height {
	NSString *fmt = nil;
	if ([self.featuredImage rangeOfString:@"mshots/"].location == NSNotFound) {
		fmt = @"https://i0.wp.com/%@?resize=%i,%i";
	} else {
		fmt = @"%@?w=%i&h=%i";
	}
	return [NSString stringWithFormat:fmt, self.featuredImage, width, height];
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
				 loadingMore:(BOOL)loadingMore
					 success:(WordPressComApiRestSuccessResponseBlock)success
					 failure:(WordPressComApiRestSuccessFailureBlock)failure {
	
	[[WordPressComApi sharedApi] getPath:path
							  parameters:params
								 success:^(AFHTTPRequestOperation *operation, id responseObject) {
									 
									 NSArray *postsArr = [responseObject arrayForKey:@"posts"];
									 if (postsArr) {									 
										 [ReaderPost syncPostsFromEndpoint:path
																 withArray:postsArr
															   withContext:[[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext]
																   success:^{
																	   if (success) {
																		   success(operation, responseObject);
																	   }
																   }];
			
										 [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:ReaderLastSyncDateKey];
										 [NSUserDefaults resetStandardUserDefaults];
										 
										 if (!loadingMore) {
											 NSTimeInterval interval = - (60 * 60 * 24 * 7); // 7 days.
											 [ReaderPost deletePostsSyncedEarlierThan:[NSDate dateWithTimeInterval:interval sinceDate:[NSDate date]] withContext:[[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext]];
										 }
										 return;
									 }
									 
									 if (success) {
										 success(operation, responseObject);
									 }
									 
								 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
									 if (failure) {
										 failure(operation, error);
									 }
								 }];

}


+ (void)fetchPostsWithCompletionHandler:(void (^)(NSInteger count, NSError *error))completionHandler {
	NSString *endpoint = [self currentEndpoint];
	NSNumber *numberToSync = [NSNumber numberWithInteger:ReaderPostsToSync];
	NSDictionary *params = @{@"number":numberToSync, @"per_page":numberToSync};
	
	[self getPostsFromEndpoint:endpoint
				withParameters:params
				   loadingMore:NO
					   success:^(AFHTTPRequestOperation *operation, id responseObject) {
						   NSArray *postsArr = [responseObject arrayForKey:@"posts"];
						   if(completionHandler){
							   completionHandler([postsArr count], NULL);
						   }
					   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
						   completionHandler(0, error);
					   }];
}

@end
