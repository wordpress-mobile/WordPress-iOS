//
//  ReaderTest.m
//  WordPress
//
//  Created by Eric J on 3/22/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <OHHTTPStubs/OHHTTPStubs.h>
#import "ReaderTest.h"
#import	"WordPressComApi.h"
#import "CoreDataTestHelper.h"
#import "AsyncTestHelper.h"
#import "ReaderPost.h"

@interface ReaderTest()

- (void)checkResultForPath:(NSString *)path andResponseObject:(id)responseObject;

@end

@implementation ReaderTest

/*
 Data
 */
- (void)testPostsUpdateNotDuplicated {
	
	NSDictionary *dict = @{
		@"ID":@106,
		@"comment_count":@0,
		@"is_following" : @01145157,
		@"is_liked" : @1,
		@"is_reblog" : @0,
		@"post_author" : @{
			@"avatar_URL" : @"https://2.gravatar.com/avatar/1d2bad37f7498bd2445d74875357814b",
			@"blog_name" : @"Blog name",
			@"display_name" : @"Anon",
			@"email" : @"",
			@"name" : @"anon",
			@"profile_URL" : @"http://gravatar.com/anon",
		},
		@"post_content" : @"some content",
		@"post_content_full" : @"some content",
		@"post_date_gmt" : @"2013-03-31 16:03:41",
		@"post_featured_media" : @"",
		@"post_format" : @"status",
		@"post_like_count" : @4,
		@"post_permalink" : @"http://testblog.wordpress.org/2013/03/31/a-title/",
		@"post_time_since" : @"1 day, 23 hours ago",
		@"post_timestamp" : @1364828459,
		@"post_title" : @"A title...",
		@"post_topics" : @"",
		@"total_comments" : @0,
		@"total_likes" : @4
	};
	
	NSError *error;
	NSManagedObjectContext *moc = [[CoreDataTestHelper sharedHelper] managedObjectContext];
	NSString *endpoint = @"freshly-pressed";

	// Check the count before we do anything.
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderPost"];
    request.predicate = [NSPredicate predicateWithFormat:@"(postID = %@) AND (endpoint = %@)", [dict objectForKey:@"ID"], endpoint];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date_created_gmt" ascending:YES]];
	
    NSArray *results = [moc executeFetchRequest:request error:&error];
	NSUInteger startingCount = [results count];
	
	// First save one
	[ReaderPost createOrUpdateWithDictionary:dict forEndpoint:endpoint withContext:moc];
	[moc save:&error];
	
	// Check the count
	request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderPost"];
    request.predicate = [NSPredicate predicateWithFormat:@"(postID = %@) AND (endpoint = %@)", [dict objectForKey:@"ID"], endpoint];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date_created_gmt" ascending:YES]];
	
    results = [moc executeFetchRequest:request error:&error];
	NSUInteger firstCount = [results count];
	
	// Now save another
	[ReaderPost createOrUpdateWithDictionary:dict forEndpoint:endpoint withContext:moc];
	[moc save:&error];
	
	// Check the count
	request = [NSFetchRequest fetchRequestWithEntityName:@"ReaderPost"];
    request.predicate = [NSPredicate predicateWithFormat:@"(postID = %@) AND (endpoint = %@)", [dict objectForKey:@"ID"], endpoint];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date_created_gmt" ascending:YES]];
	
    results = [moc executeFetchRequest:request error:&error];
	NSUInteger secondCount = [results count];
	
	// See how'd we do.
	NSLog(@"Starting Count:  %i  First Count:  %i  Second Cound: %i", startingCount, firstCount, secondCount);
	STAssertEquals(firstCount, secondCount, @"Count's should be equal.");

}


/*
 * API
 */

- (void)testGetTopics {
		
	ATHStart();
	[ReaderPost getReaderTopicsWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
		ATHNotify();
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		STFail(@"Call to Reader Topics Failed: %@", error);
		ATHNotify();
	}];
	ATHEnd();
}


- (void)testGetComments {
		
	ATHStart();
	[ReaderPost getCommentsForPost:7 fromSite:@"en.blog.wordpress.com" withParameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		ATHNotify();
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		STFail(@"Call to Reader Comments Failed: %@", error);
		ATHNotify();
	}];
	ATHEnd();
	
}


- (void)checkResultForPath:(NSString *)path andResponseObject:(id)responseObject {

	NSDictionary *resp = (NSDictionary *)responseObject;
	NSArray *postsArr = [resp objectForKey:@"posts"];
    if (!postsArr || ![postsArr isKindOfClass:[NSArray class]]) {
        STFail(@"Posts is not an array");
        return;
    }
	NSManagedObjectContext *moc = [[CoreDataTestHelper sharedHelper] managedObjectContext];
	[ReaderPost syncPostsFromEndpoint:path withArray:postsArr withContext:moc];

	NSArray *posts = [ReaderPost fetchPostsForEndpoint:path withContext:moc];
	
	if([posts count] == 0) {
		STFail(@"No posts synced for path : %@", path);
	}
	NSLog(@"Syced: %i, Fetched: %i", [postsArr count], [posts count]);
	STAssertEquals([posts count], [postsArr count], @"Synced posts should equal fetched posts.");

}


- (void)testGetPostsFreshlyPressed {
	
	ATHStart();
	NSString *path = [[[ReaderPost readerEndpoints] objectAtIndex:0] objectForKey:@"endpoint"];
	[ReaderPost getPostsFromEndpoint:path withParameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {

		[self checkResultForPath:path andResponseObject:responseObject];
		ATHNotify();
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		STFail(@"Call to Reader Freshly Pressed Failed: %@", error);
		ATHNotify();
	}];
	
	ATHEnd();
	
}


- (void)testGetPostsFollowing {
	
	ATHStart();
	NSString *path = [[[ReaderPost readerEndpoints] objectAtIndex:2] objectForKey:@"endpoint"];
	[ReaderPost getPostsFromEndpoint:path withParameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		
		[self checkResultForPath:path andResponseObject:responseObject];
		ATHNotify();

	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		STFail(@"Call to Reader Following Failed: %@", error);
		ATHNotify();
	}];
	ATHEnd();
	
}


- (void)testGetPostsLikes {
	
	ATHStart();
	NSString *path = [[[ReaderPost readerEndpoints] objectAtIndex:1] objectForKey:@"endpoint"];
	[ReaderPost getPostsFromEndpoint:path withParameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		
		[self checkResultForPath:path andResponseObject:responseObject];
		ATHNotify();
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		STFail(@"Call to Reader Liked Failed: %@", error);
		ATHNotify();
	}];
	ATHEnd();
	
}


- (void)testGetPostsForTopic {
	
	ATHStart();
	NSString *path = [[[ReaderPost readerEndpoints] objectAtIndex:3] objectForKey:@"endpoint"];
	path = [NSString stringWithFormat:path, @"1"];
	[ReaderPost getPostsFromEndpoint:path withParameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {

		[self checkResultForPath:path andResponseObject:responseObject];
		ATHNotify();
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		STFail(@"Call to Reader Topic Posts Failed: %@", error);
		ATHNotify();
	}];
	ATHEnd();
	
}


@end
