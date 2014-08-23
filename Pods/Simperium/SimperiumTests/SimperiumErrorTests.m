//
//  SimperiumErrorTests.m
//  SimperiumErrorTests
//
//  Created by Michael Johnston on 11-04-19.
//  Copyright 2011 Simperium. All rights reserved.
//

#import "SimperiumTests.h"
#import "Config.h"
#import "Farm.h"
#import "SPBucket.h"
#import "DiffMatchPatch.h"


@interface SimperiumErrorTests : SimperiumTests

@end

@implementation SimperiumErrorTests

- (void)testDeletion404
{
    // Leader sends an object to a follower, follower goes offline, both make changes, follower reconnects
    Farm *leader = [self createFarm:@"leader"];
    Farm *follower = [self createFarm:@"follower"];
    [leader start];
    [follower start];
    
    NSArray *farmArray = [NSArray arrayWithObjects:leader, follower, nil];
    [leader connect];
    [follower connect];
    [self waitFor:1.0];
    
    SPBucket *leaderBucket = [leader.simperium bucketForName:[Config entityName]];
    SPBucket *followerBucket = [follower.simperium bucketForName:[Config entityName]];
    
    leader.config = [leaderBucket insertNewObject];
    leader.config.captainsLog = @"1";
    [leader.simperium save];
    leader.expectedAcknowledgments = 1;
    follower.expectedAdditions = 1;
    XCTAssertTrue([self waitForCompletion: 4.0 farmArray:farmArray], @"timed out (adding)");
    [self resetExpectations: farmArray];
    [self ensureFarmsEqual:farmArray entityName:[Config entityName]];
    NSLog(@"****************************DISCONNECT*************************");
    [follower disconnect];
    
    // Delete on leader and sync
    [leaderBucket deleteObject:leader.config];
    leader.expectedAcknowledgments = 1;
    [leader.simperium save];
    XCTAssertTrue([self waitForCompletion: 4.0 farmArray:farmArray], @"timed out (deleting)");
    [self resetExpectations: farmArray];
    
    // Delete on follower before it syncs to force a 404
    [followerBucket deleteObject:follower.config];
    follower.expectedDeletions = 1;
    [follower.simperium save];
    [self waitFor:0.01];
    NSLog(@"****************************RECONNECT*************************");
    [follower connect];
    XCTAssertTrue([self waitForCompletion:4.0 farmArray:farmArray], @"timed out (changing)");
    NSLog(@"%@ end", self.name);
}

@end
