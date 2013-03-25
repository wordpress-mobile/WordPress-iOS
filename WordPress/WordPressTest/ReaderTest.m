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

@implementation ReaderTest


/*
 * API
 */

- (void)testGetTopics {
		
	ATHStart();
	[[WordPressComApi sharedApi] getReaderTopicsWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
		ATHNotify();
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		STFail(@"Call to Reader Topics Failed: %@", error);
		ATHNotify();
	}];
	ATHWait();
}

- (void)testGetComments {
		
	ATHStart();
	[[WordPressComApi sharedApi] getCommentsForPost:7 fromSite:@"en.blog.wordpress.com" success:^(AFHTTPRequestOperation *operation, id responseObject) {
		ATHNotify();
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		STFail(@"Call to Reader Comments Failed: %@", error);
		ATHNotify();
	}];
	ATHWait();
	
}

- (void)testGetPostsFreshlyPressed {
	
	ATHStart();
	[[WordPressComApi sharedApi] getPostsFromSource:RESTPostSourceFreshly forID:nil withParameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		ATHNotify();
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		STFail(@"Call to Reader Freshly Pressed Failed: %@", error);
		ATHNotify();
	}];
	ATHWait();
	
}

- (void)testGetPostsFollowing {
	
	ATHStart();
	[[WordPressComApi sharedApi] getPostsFromSource:RESTPostSourceFollowing forID:nil withParameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		ATHNotify();
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		STFail(@"Call to Reader Following Failed: %@", error);
		ATHNotify();
	}];
	ATHWait();
	
}

- (void)testGetPostsLikes {
	
	ATHStart();
	[[WordPressComApi sharedApi] getPostsFromSource:RESTPostSourceLiked forID:nil withParameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		ATHNotify();
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		STFail(@"Call to Reader Liked Failed: %@", error);
		ATHNotify();
	}];
	ATHWait();
	
}

- (void)testGetPostsForTopic {
	
	ATHStart();
	[[WordPressComApi sharedApi] getPostsFromSource:RESTPostSourceTopic forID:@"1" withParameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		ATHNotify();
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		STFail(@"Call to Reader Topic Posts Failed: %@", error);
		ATHNotify();
	}];
	ATHWait();
	
}

- (void)testGetPostForSite {
	
	ATHStart();
	[[WordPressComApi sharedApi] getPostsFromSource:RESTPostSourceSite forID:@"en.blog.wordpress.com" withParameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		ATHNotify();
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		STFail(@"Call to Reader Site Posts Failed: %@", error);
		ATHNotify();
	}];
	ATHWait();

}


@end
