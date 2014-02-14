//
//  RemoteDebugTests.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 11/11/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XCTestCase+Simperium.h"
#import "MockSimperium.h"
#import "MockWebSocketInterface.h"
#import "SPLogger.h"
#import "JSONKit+Simperium.h"
#import "Config.h"


@interface RemoteDebugTests : XCTestCase

@end

@implementation RemoteDebugTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testRemoteLogging {
	//	log:<log level>
	//		log level = int, 0 = OFF, 1 = regular, 2 = verbose?
	
	MockSimperium* s = [MockSimperium mockSimperium];
	
	[s.mockWebSocketInterface mockReceiveMessage:@"log:0"];
	XCTAssertFalse(s.verboseLoggingEnabled, @"Error disabling verbose mode");
	XCTAssertFalse(s.remoteLoggingEnabled,	@"Error disabling remote logging");
	
	[s.mockWebSocketInterface mockReceiveMessage:@"log:1"];
	XCTAssertFalse(s.verboseLoggingEnabled, @"Error disabling verbose logging");
	XCTAssertTrue(s.remoteLoggingEnabled,	@"Error enabling remote logging");
	
	[s.mockWebSocketInterface mockReceiveMessage:@"log:2"];
	XCTAssertTrue(s.verboseLoggingEnabled,	@"Error enabling verbose logging");
	XCTAssertTrue(s.remoteLoggingEnabled,	@"Error enabling remote logging");

	// Simulate an error
	SPLogLevels logLevel = SPLogLevelsVerbose;
	NSString* error = @"Simulating Error Message";
	SPLogError(@"%@", error);

	// Release main thread so the log gets posted. (WebSocket gets called only in the main thread)
	[self waitFor:0.1];
	
	// Check if the error got actually posted. We expect:
	//		log:{ "log" : "log message" }
	NSDictionary *payload	= @{ @"log" : error };
	NSString *message		= [NSString stringWithFormat:@"log:%@", [payload sp_JSONString]];
	NSSet *sentMessages		= s.mockWebSocketInterface.mockSentMessages;
	XCTAssertTrue([sentMessages containsObject:message], @"Error message wasn't sent through the WebSocket interface");
}

- (void)testRemoteIndex {
	// Add a new object
	MockSimperium* s		= [MockSimperium mockSimperium];

	SPBucket* bucket		= [s bucketForName:NSStringFromClass([Config class])];
	Config* config			= [bucket insertNewObject];
	config.captainsLog		= @"Alala lala long long le long long long";
	[s save];

	// Let's unlock the main thread. WebSocket interaction is always executed on the main thread.
	[self waitFor:1.0f];
	
	// Index Request
	//		0:index   << 0 is the channel number
	MockWebSocketChannel* channel	= [s.mockWebSocketInterface mockChannelForBucket:bucket];
	NSString* message				= [NSString stringWithFormat:@"%d:index", channel.number];
	[s.mockWebSocketInterface mockReceiveMessage:message];
	
	//	Index Response
	//		0:index:{ current: <cv>, index: { {id: <eid>, v: <version>}, ... }, pending: { { id: <eid>, sv: <version>, ccid: <ccid> }, ... }, extra: { ? } }
	BOOL responseSent = NO;
	for (id sent in s.mockWebSocketInterface.mockSentMessages) {
		NSRange range			= [sent rangeOfString:@":"];
		NSString *msgChannel	= [sent substringToIndex:range.location];
		NSString *msgCommand	= [sent substringFromIndex:range.location+range.length];
		
		if ([msgChannel intValue] != channel.number || [msgCommand hasPrefix:@"index:"] == NO) {
			continue;
		}
		
		responseSent = YES;
		range = [msgCommand rangeOfString:@":"];
		NSDictionary* payload = [[msgCommand substringFromIndex:range.location+range.length] sp_objectFromJSONString];
		
		NSArray* index = payload[@"index"];
		NSString* current = payload[@"current"];
		NSArray* pendings = payload[@"pendings"];
		
		XCTAssertNotNil(index,			@"Missing current field");
		XCTAssertNotNil(current,		@"Missing current field");
		XCTAssertNotNil(pendings,		@"Missing current field");
		XCTAssertTrue(index.count == 1,	@"Index Inconsistency");
		
		break;
	}
	
	XCTAssertTrue(responseSent, @"Index Request-Response wasn't sent!!");
}

@end
