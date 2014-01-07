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
#import "ContextManager.h"
#import "WPAccount.h"

NSInteger const ReaderTopicEndpointIndex = 3;
NSInteger const ReaderPostSummaryLength = 150;
NSInteger const ReaderPostsToSync = 20;
NSString *const ReaderLastSyncDateKey = @"ReaderLastSyncDate";
NSString *const ReaderCurrentTopicKey = @"ReaderCurrentTopicKey";
NSString *const ReaderTopicsArrayKey = @"ReaderTopicsArrayKey";
NSString *const ReaderExtrasArrayKey = @"ReaderExtrasArrayKey";

// These keys are used in the getStoredComment method
NSString * const ReaderPostStoredCommentIDKey = @"commentID";
NSString * const ReaderPostStoredCommentTextKey = @"comment";

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
@dynamic isBlogPrivate;
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
@dynamic account;
@dynamic primaryTagName;
@dynamic primaryTagSlug;
@dynamic tags;

+ (NSArray *)readerEndpoints {
	static NSArray *endpoints = nil;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		
		NSDictionary *fpDict = @{@"title": NSLocalizedString(@"Freshly Pressed", @""), @"endpoint":@"freshly-pressed", @"default":@YES};
		NSDictionary *follows = @{@"title": NSLocalizedString(@"Blogs I Follow", @""), @"endpoint":@"reader/following", @"default":@YES};
		NSDictionary *likes = @{@"title": NSLocalizedString(@"Posts I Like", @""), @"endpoint":@"reader/liked", @"default":@YES};
		NSDictionary *topic = @{@"title": NSLocalizedString(@"Topics", @""), @"endpoint":@"reader/topics/%@", @"default":@NO};
		
		endpoints = @[follows, fpDict, likes, topic];
		
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
    DDLogMethod();
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


+ (void)syncPostsFromEndpoint:(NSString *)endpoint withArray:(NSArray *)arr success:(void (^)())success {
    DDLogMethod();
    if (![arr isKindOfClass:[NSArray class]] || [arr count] == 0) {
		if (success) {
			dispatch_async(dispatch_get_main_queue(), success);
		}
        return;
    }
    
    NSManagedObjectContext *backgroundMOC = [[ContextManager sharedInstance] backgroundContext];
    [backgroundMOC performBlock:^{
        for (NSDictionary *postData in arr) {
            if (![postData isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            [self createOrUpdateWithDictionary:postData forEndpoint:endpoint withContext:backgroundMOC];
        }
        
        [[ContextManager sharedInstance] saveContext:backgroundMOC];
        if (success) {
            dispatch_async(dispatch_get_main_queue(), success);
        }
    }];
}


+ (void)deletePostsSyncedEarlierThan:(NSDate *)syncedDate {
    DDLogMethod();
    NSManagedObjectContext *context = [[ContextManager sharedInstance] backgroundContext];
    [context performBlock:^{
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:[NSEntityDescription entityForName:@"ReaderPost" inManagedObjectContext:context]];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(dateSynced < %@)", syncedDate];
        [request setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *array = [context executeFetchRequest:request error:&error];
        
        if ([array count]) {
            DDLogInfo(@"Deleting %i ReaderPosts synced earlier than: %@ ", [array count], syncedDate);
            for (ReaderPost *post in array) {
                [context deleteObject:post];
            }
        }
        [[ContextManager sharedInstance] saveContext:context];
    }];
}


+ (void)createOrUpdateWithDictionary:(NSDictionary *)dict forEndpoint:(NSString *)endpoint withContext:(NSManagedObjectContext *)context {
	NSNumber *blogSiteID = [dict numberForKey:@"site_id"];
	NSNumber *siteID = [dict numberForKey:@"blog_id"];
	NSNumber *postID = [dict numberForKey:@"ID"];

    // Some endpoints (e.g. tags) use different case
    if (siteID == nil) {
        siteID = [dict numberForKey:@"site_ID"];
        blogSiteID = [dict numberForKey:@"site_ID"];
    }

	// following, likes and topics endpoints
	if ([dict valueForKey:@"blog_site_id"] != nil) {
		blogSiteID = [dict numberForKey:@"blog_site_id"];
	}
	
	// freshly pressed
	if ([dict valueForKey:@"editorial"]) {
		NSDictionary *ed = [dict objectForKey:@"editorial"];
		blogSiteID = [ed numberForKey:@"site_id"];
		siteID = [ed numberForKey:@"blog_id"];
	}
	
	// If the post is from the feedbag it won't have a siteID or postID (wtf!).
	// Substitute the feed_id and feed_item_id for these. Since should be unique values for the feedback
	// and we should avoid collisons with non-feedbag posts by checking the blogSiteID.
	// Feedbag posts will never be .com posts and should never show comments, likes or reblogs options in the reader.
	// Possible in following, likes and topics endpoints
	if ([dict valueForKey:@"feed_item_id"]) {
		postID = [dict numberForKey:@"feed_item_id"];
		siteID = [dict numberForKey:@"feed_id"];
	}
    
    // single reader post loaded from wordpress://viewpost handler
    if ([dict valueForKey:@"meta"]) {
        NSDictionary *metaSite = [dict objectForKeyPath:@"meta.data.site"];
        if (metaSite) {
            // hardcode blog_site_id to 1 for now because only WordPress.com and Jetpack blogs will
            // return from the endpoint anyway. this should be changed to data from the API once the
            // API returns the data.
            blogSiteID = @1;
            siteID = [metaSite numberForKey:@"ID"];
        }
    };

	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderPost"];
    request.predicate = [NSPredicate predicateWithFormat:@"(postID = %@) AND (siteID = %@) AND (blogSiteID = %@) AND (endpoint = %@)", postID, siteID, blogSiteID, endpoint];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date_created_gmt" ascending:YES]];
    request.fetchLimit = 1;
    
    NSError *error;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if(error != nil){
        DDLogError(@"Error finding ReaderPost: %@", error);
        return;
    }
	
	ReaderPost *post;
    if ([results count] > 0) {
		post = (ReaderPost *)[results objectAtIndex:0];

    } else {
		post = (ReaderPost *)[NSEntityDescription insertNewObjectForEntityForName:@"ReaderPost"
														   inManagedObjectContext:context];
		post.postID = postID;
		post.siteID = siteID;
		post.blogSiteID = blogSiteID;
		post.endpoint = endpoint;
    }
    
    // Set account on the post, but only if signed in
    if ([WPAccount defaultWordPressComAccount] != nil) {
        post.account = (WPAccount *)[context objectWithID:[WPAccount defaultWordPressComAccount].objectID];
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
		self.sortDate = [DateUtils dateFromISOString:[dict objectForKey:@"date"]];
	}
	
    if ([dict valueForKey:@"meta"]) {
        NSDictionary *meta_root = [dict objectForKey:@"meta"];
        NSDictionary *meta_data = [meta_root objectForKey:@"data"];
        NSDictionary *meta_site = [meta_data objectForKey:@"site"];
        
        self.blogName = [[meta_site stringForKey:@"name"] stringByDecodingXMLCharacters];
    };
    
	NSDictionary *author = [dict objectForKey:@"author"];
	self.author = [author stringForKey:@"name"];
	self.authorURL = [author stringForKey:@"URL"];
	self.authorAvatarURL = [author stringForKey:@"avatar_URL"];
	// email can return a boolean.
	if([[author objectForKey:@"email"] isKindOfClass:[NSString class]]) {
		self.authorEmail = [author stringForKey:@"email"];
	}
	
	NSString *content = [dict stringForKey:@"content"];
    if ([self containsVideoPress:content]) {
        content = [self formatVideoPress:content];
    }
	self.content = [self normalizeParagraphs:content];
	self.commentsOpen = [dict numberForKey:@"comments_open"];
	
	self.date_created_gmt = [DateUtils dateFromISOString:[dict objectForKey:@"date"]];
	
	self.likeCount = [dict numberForKey:@"like_count"];
	self.permaLink = [dict stringForKey:@"URL"];
	self.postTitle = [[[dict stringForKey:@"title"] stringByDecodingXMLCharacters] trim];
    self.postTitle = [self.postTitle stringByStrippingHTML];
	
	self.isLiked = [dict numberForKey:@"i_like"];
	
	NSURL *url = [NSURL URLWithString:self.permaLink];
	self.blogURL = [NSString stringWithFormat:@"%@://%@/", url.scheme, url.host];
	
	self.summary = [self createSummary:self.content makePlainText:YES];
    
    NSDictionary *tagsDict = [dict objectForKey:@"tags"];
    NSArray *tagsList = [NSArray arrayWithArray:[tagsDict allKeys]];
    self.tags = [tagsList componentsJoinedByString:@", "];
    
    if ([tagsDict count] > 0) {
        NSDictionary *tagDict = [[tagsDict allValues] objectAtIndex:0];
        self.primaryTagSlug = tagDict[@"slug"];
        self.primaryTagName = tagDict[@"name"];
        self.primaryTagName = [self.primaryTagName stringByDecodingXMLCharacters];
    }
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
	
    NSString *content = [dict stringForKey:@"post_content_full"];
    if ([self containsVideoPress:content]) {
        content = [self formatVideoPress:content];
    }
	self.content = [self normalizeParagraphs:content];
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
    self.postTitle = [self.postTitle stringByStrippingHTML];
	
    // blog_public is either a 1 or a -1.
    NSInteger isPublic = [[dict numberForKey:@"blog_public"] integerValue];
    self.isBlogPrivate = [NSNumber numberWithBool:(1 > isPublic)];
    
	self.isLiked = [dict numberForKey:@"is_liked"];
	
	NSString *summary = [self makePlainText:self.content];
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
    
    NSDictionary *tagsDict = [dict dictionaryForKey:@"topics"];
    
    if ([tagsDict count] > 0) {
        NSArray *tagsList = [NSArray arrayWithArray:[tagsDict allValues]];
        self.tags = [tagsList componentsJoinedByString:@", "];
    }
    
    NSDictionary *primaryTagDict = [dict dictionaryForKey:@"primary_tag"];
    if ([primaryTagDict isKindOfClass:[NSDictionary class]]) {
        self.primaryTagSlug = [primaryTagDict stringForKey:@"slug"];
        self.primaryTagName = [primaryTagDict stringForKey:@"name"];
        self.primaryTagName = [self.primaryTagName stringByDecodingXMLCharacters];
    } else if ([tagsDict count] > 0) {
        self.primaryTagSlug = [[tagsDict allKeys] objectAtIndex:0];
        self.primaryTagName = [tagsDict stringForKey:self.primaryTagSlug];
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
	return [[[string stringByRemovingScriptsAndStrippingHTML] stringByDecodingXMLCharacters] trim];
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

	[[[WPAccount defaultWordPressComAccount] restApi] postPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
	
	[[[WPAccount defaultWordPressComAccount] restApi] postPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
	[[[WPAccount defaultWordPressComAccount] restApi] postPath:path parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	NSTimeInterval diff = [[NSDate date] timeIntervalSinceDate:date];
    if (diff < 86400) {
        formatter.dateStyle = NSDateFormatterNoStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
    } else {
        formatter.dateStyle = NSDateFormatterShortStyle;
        formatter.timeStyle = NSDateFormatterNoStyle;
    }
    formatter.doesRelativeDateFormatting = YES;
    return [formatter stringFromDate:date];
}

- (BOOL)isFollowable {
    return self.siteID != nil;
}

- (BOOL)isFreshlyPressed {
	return ([self.endpoint rangeOfString:@"freshly-pressed"].location != NSNotFound)? YES : NO;
}


- (BOOL)isBlogsIFollow {
	return ([self.endpoint rangeOfString:@"reader/following"].location != NSNotFound)? YES : NO;
}


- (BOOL)isPrivate {
    return [self.isBlogPrivate boolValue];
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
	return @{ReaderPostStoredCommentIDKey:commentID, ReaderPostStoredCommentTextKey:commentText};
}

- (NSString *)authorString {
    if ([self.blogName length] > 0) {
        return self.blogName;
    } else if ([self.authorDisplayName length] > 0) {
        return self.authorDisplayName;
    } else {
        return self.author;
    }
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
    if (self.featuredImage) {
        return [NSURL URLWithString:self.featuredImage];
    }

    return nil;
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

- (BOOL)containsVideoPress:(NSString *)str {
    return [str rangeOfString:@"class=\"videopress-placeholder"].location != NSNotFound;
}

- (NSString *)formatVideoPress:(NSString *)str {
    NSMutableString *mstr = [str mutableCopy];
    NSError *error;
    
    // Find instances of VideoPress markup.
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<div[\\S\\s]+?<div.*class=\"videopress-placeholder[\\s\\S]*?</noscript>" options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regex matchesInString:mstr options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [mstr length])];
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        // compose videopress string

        // Find the mp4 in the markup.
        NSRegularExpression *mp4Regex = [NSRegularExpression regularExpressionWithPattern:@"mp4[\\s\\S]+?mp4" options:NSRegularExpressionCaseInsensitive error:&error];
        NSRange mp4Match = [mp4Regex rangeOfFirstMatchInString:mstr options:NSRegularExpressionCaseInsensitive range:match.range];
        if (mp4Match.location == NSNotFound) {
            DDLogError(@"%@ failed to match mp4 JSON string while formatting video press markup: %@", self, [mstr substringWithRange:match.range]);
            [mstr replaceCharactersInRange:match.range withString:@""];
            continue;
        }
        NSString *mp4 = [mstr substringWithRange:mp4Match];
        
        // Get the mp4 url.
        NSRegularExpression *srcRegex = [NSRegularExpression regularExpressionWithPattern:@"http\\S+mp4" options:NSRegularExpressionCaseInsensitive error:&error];
        NSRange srcMatch = [srcRegex rangeOfFirstMatchInString:mp4 options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [mp4 length])];
        if (srcMatch.location == NSNotFound) {
            DDLogError(@"%@ failed to match mp4 src when formatting video press markup: %@", self, mp4);
            [mstr replaceCharactersInRange:match.range withString:@""];
            continue;
        }
        NSString *src = [mp4 substringWithRange:srcMatch];
        src = [src stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
        
        // Compose a video tag to replace the default markup.
        NSString *fmt = @"<video src=\"%@\"><source src=\"%@\" type=\"video/mp4\"></video>";
        NSString *vid = [NSString stringWithFormat:fmt, src, src];
        
        [mstr replaceCharactersInRange:match.range withString:vid];
    }

    return mstr;
}

@end


@implementation ReaderPost (WordPressComApi)

+ (void)getReaderTopicsWithSuccess:(WordPressComApiRestSuccessResponseBlock)success
						   failure:(WordPressComApiRestSuccessFailureBlock)failure {
	
	NSString *path = @"reader/topics";
	
    // There should probably be a better check here
    if ([[WPAccount defaultWordPressComAccount] restApi].authToken) {
        [[WPAccount defaultWordPressComAccount].restApi getPath:path parameters:nil success:success failure:failure];
    } else {
        [[WordPressComApi anonymousApi] getPath:path parameters:nil success:success failure:failure];
    }
}


+ (void)getCommentsForPost:(NSUInteger)postID
				  fromSite:(NSString *)siteID
			withParameters:(NSDictionary*)params
				   success:(WordPressComApiRestSuccessResponseBlock)success
				   failure:(WordPressComApiRestSuccessFailureBlock)failure {
	
	NSString *path = [NSString stringWithFormat:@"sites/%@/posts/%i/replies", siteID, postID];
	
    if ([[WPAccount defaultWordPressComAccount] restApi].authToken) {
        [[WPAccount defaultWordPressComAccount].restApi getPath:path parameters:params success:success failure:failure];
    } else {
        [[WordPressComApi anonymousApi] getPath:path parameters:params success:success failure:failure];
    }
}


+ (void)getPostsFromEndpoint:(NSString *)path
			  withParameters:(NSDictionary *)params
				 loadingMore:(BOOL)loadingMore
					 success:(WordPressComApiRestSuccessResponseBlock)success
					 failure:(WordPressComApiRestSuccessFailureBlock)failure {
	DDLogMethod();
    
    WordPressComApi *api;
    if ([[WPAccount defaultWordPressComAccount] restApi].authToken) {
        api = [[WPAccount defaultWordPressComAccount] restApi];
    } else {
        api = [WordPressComApi anonymousApi];
    }
    
	[api getPath:path
							  parameters:params
								 success:^(AFHTTPRequestOperation *operation, id responseObject) {
									 
									 NSArray *postsArr = [responseObject arrayForKey:@"posts"];
									 if (postsArr) {
										 [ReaderPost syncPostsFromEndpoint:path
																 withArray:postsArr
																   success:^{
																	   if (success) {
																		   success(operation, responseObject);
																	   }
																   }];
			
										 [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:ReaderLastSyncDateKey];
										 [NSUserDefaults resetStandardUserDefaults];
										 
										 if (!loadingMore) {
											 NSTimeInterval interval = - (60 * 60 * 24 * 7); // 7 days.
											 [ReaderPost deletePostsSyncedEarlierThan:[NSDate dateWithTimeInterval:interval sinceDate:[NSDate date]]] ;
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
							   completionHandler([postsArr count], nil);
						   }
					   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
						   completionHandler(0, error);
					   }];
}

@end
