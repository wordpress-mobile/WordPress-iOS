//
//  SimperiumIndexTests.m
//  SimperiumIndexTests
//
//  Created by Michael Johnston on 11-04-19.
//  Copyright 2011 Simperium. All rights reserved.
//

#import "SimperiumTests.h"
#import "Config.h"
#import "Farm.h"
#import "SPBucket.h"
#import "DiffMatchPatch.h"


@interface SimperiumIndexTests : SimperiumTests

@end

@implementation SimperiumIndexTests

- (void)testIndex
{
    NSLog(@"%@ start", self.name);

    // Leader sends an object to follower, but make follower get it from the index
    Farm *leader = [self createFarm:@"leader"];
    Farm *follower = [self createFarm:@"follower"];
    leader.expectedIndexCompletions = 1;
    [leader start];
    [leader connect];
    XCTAssertTrue([self waitForCompletion], @"timed out");
    
    NSNumber *refWarpSpeed = [NSNumber numberWithInt:2];
    leader.config = [[leader.simperium bucketForName:[Config entityName]] insertNewObject];
    leader.config.warpSpeed = refWarpSpeed;
    [leader.simperium save];
    leader.expectedAcknowledgments = 1;
    XCTAssertTrue([self waitForCompletion], @"timed out");
    
    // Make a change to ensure version numbers increase
    refWarpSpeed = [NSNumber numberWithInt:4];
    NSString *refCaptainsLog = @"Hi!!!";
    NSNumber *refShieldPercent = [NSNumber numberWithFloat:2.718];
    leader.config.warpSpeed = refWarpSpeed;
    leader.config.captainsLog = refCaptainsLog;
    leader.config.shieldPercent = refShieldPercent;
    [leader.simperium save];
    leader.expectedAcknowledgments = 1;
    XCTAssertTrue([self waitForCompletion], @"timed out (changing)");

    // The object was synced, now connect with the follower
    [follower start];
    
    [self resetExpectations:self.farms];
    follower.expectedIndexCompletions = 1;
    [self expectAdditions:1 deletions:0 changes:0 fromLeader:leader expectAcks:NO];
    [follower connect];
	
    XCTAssertTrue([self waitForCompletion], @"timed out");
    
    [self ensureFarmsEqual:self.farms entityName:[Config entityName]];
    NSLog(@"%@ end", self.name);     
}

- (void)testLargerIndex
{
    NSLog(@"%@ start", self.name);
    // Leader sends an object to followers, but make followers get it from the index
    Farm *leader    = [self createFarm:@"leader"];
    Farm *follower  = [self createFarm:@"follower"];
    
    self.farms      = [NSMutableArray arrayWithObjects:leader, follower, nil];
    
    [leader start];
    [leader connect];
    [self waitFor:5.0];
    
    NSNumber *refWarpSpeed = @(2);
    int numObjects = 2;
    for (int i=0; i<numObjects; i++) {
        leader.config = [[leader.simperium bucketForName:[Config entityName]] insertNewObject];
        leader.config.warpSpeed = refWarpSpeed;
    }
    [leader.simperium save];
    leader.expectedAcknowledgments = numObjects;
    
    XCTAssertTrue([self waitForCompletion:3.0 farmArray:@[ leader ]], @"timed out");
    
	// Set the new expectations, before connecting
    [self resetExpectations:self.farms];
    [self expectAdditions:numObjects deletions:0 changes:0 fromLeader:leader expectAcks:NO];
	
    // The object was synced, now connect with the followers
    for (Farm *farm in self.farms) {
        if (farm == leader) {
            continue;
		}
        [farm start];
        [farm connect];
    }
    
	// Now it's safe to wait
    XCTAssertTrue([self waitForCompletion], @"timed out");
    [self ensureFarmsEqual:self.farms entityName:[Config entityName]];

    NSLog(@"%@ end", self.name);
}

// This test is known to break for the HTTP implementation. The reason is that POST responses aren't processed
// directly for acknowledgments. Instead, the response from a subsequent GET is used for acks. The problem
// is this subsequent GET uses the last known cv, which this test purposely breaks by exceeding the 50 change
// limit. The GET will 404, triggering a re-index before changes have even been acknowledged.
- (void)testReindex
{
    NSLog(@"%@ start", self.name);
    // Leader sends an object to a follower, follower goes offline, both make changes, follower reconnects
    Farm *leader = [self createFarm:@"leader"];
    Farm *follower = [self createFarm:@"follower"];
    [leader start];
    [follower start];
    leader.expectedIndexCompletions = 1;
    follower.expectedIndexCompletions = 1;    
    [leader connect];
    [follower connect];
    XCTAssertTrue([self waitForCompletion: 4.0 farmArray:self.farms], @"timed out (initial index)");
    [self resetExpectations:self.farms];
    
    NSLog(@"****************************ADD ONE*************************");
    // Add one object
    leader.config = [[leader.simperium bucketForName:[Config entityName]] insertNewObject];
    leader.config.captainsLog = @"a";
    [leader.simperium save];
    leader.expectedAcknowledgments = 1;
    follower.expectedAdditions = 1;
    XCTAssertTrue([self waitForCompletion: 4.0 farmArray:self.farms], @"timed out (adding one)");
    [self resetExpectations:self.farms];
    [self ensureFarmsEqual:self.farms entityName:[Config entityName]];
    NSLog(@"*********************FOLLOWER DISCONNECT*********************");
    [follower disconnect];

    // Add 50 objects to push the cv off the back of the queue (max 50 versions)
    int numConfigs = 50;
    NSLog(@"****************************ADD MANY*************************");
    for (int i=0; i<numConfigs; i++) {
        Config *config = [[leader.simperium bucketForName:[Config entityName]] insertNewObject];
        config.warpSpeed = @(2);
        config.captainsLog = @"Hi";
        config.shieldPercent = @(3.14);
    }
    [leader.simperium save];
    [self expectAdditions:numConfigs deletions:0 changes:0 fromLeader:leader expectAcks:YES];
    XCTAssertTrue([self waitForCompletion: numConfigs/3.0 farmArray:[NSArray arrayWithObject:leader]], @"timed out (adding many)");
    
    NSLog(@"**********************FOLLOWER RECONNECT********************");
    [self resetExpectations:self.farms];
    follower.expectedAdditions = numConfigs;
    [follower connect];

    // Expect 404 and reindex?
    XCTAssertTrue([self waitForCompletion:numConfigs/3.0 farmArray:self.farms], @"timed out (receiving many)");
    [self ensureFarmsEqual:self.farms entityName:[Config entityName]];
    
    NSLog(@"%@ end", self.name);
}

// If you delete more than 50 items in bulk, another client will fail to receive changes past the 50th
// (max 50 versions in Simperium). A reindex should be triggered, and that reindex should cross-check with
// local objects, and delete any that exist locally but not remotely. Any objects created locally but
// not yet synced should be preserved.
- (void)testDeletionReindex
{
    NSLog(@"%@ start", self.name);
    // Leader sends an object to a follower, follower goes offline, both make changes, follower reconnects
    Farm *leader = [self createFarm:@"leader"];
    Farm *follower = [self createFarm:@"follower"];
    [leader start];
    [follower start];
    leader.expectedIndexCompletions = 1;
    follower.expectedIndexCompletions = 1;
    [leader connect];
    [follower connect];
    XCTAssertTrue([self waitForCompletion: 4.0 farmArray:self.farms], @"timed out (initial index)");
    [self resetExpectations:self.farms];
    
    SPBucket *leaderBucket = [leader.simperium bucketForName:[Config entityName]];
    SPBucket *followerBucket = [follower.simperium bucketForName:[Config entityName]];
    
    // Add 50 objects
    int numConfigs = 50;
    NSLog(@"****************************ADD MANY*************************");
    for (int i=0; i<numConfigs; i++) {
        Config *config = [leaderBucket insertNewObject];
        config.warpSpeed = @(2);
        config.captainsLog = @"Hi";
        config.shieldPercent = @(3.14);
    }
    [self expectAdditions:numConfigs deletions:0 changes:0 fromLeader:leader expectAcks:YES];
    [leader.simperium save];
    
    XCTAssertTrue([self waitForCompletion: numConfigs/3.0 farmArray:self.farms], @"timed out (adding many)");
    XCTAssertTrue([[leaderBucket allObjects] count] == numConfigs, @"didn't add correct number (leader)");
    XCTAssertTrue([[followerBucket allObjects] count] == numConfigs, @"didn't add correct number (follower)");
    [self ensureFarmsEqual:self.farms entityName:[Config entityName]];
    [self resetExpectations:self.farms];
    
    // Add 20 more
    numConfigs = 20;
    NSLog(@"****************************ADD MORE*************************");
    for (int i=0; i<numConfigs; i++) {
        Config *config = [leaderBucket insertNewObject];
        config.warpSpeed = @(2);
        config.captainsLog = @"Hi";
        config.shieldPercent = @(3.14);
    }
    [self expectAdditions:numConfigs deletions:0 changes:0 fromLeader:leader expectAcks:YES];
    [leader.simperium save];
    
    XCTAssertTrue([self waitForCompletion:numConfigs/3.0 farmArray:self.farms], @"timed out (receiving many)");
    [self ensureFarmsEqual:self.farms entityName:[Config entityName]];
    [self resetExpectations:self.farms];
    
    [self waitFor:2.0];
    [follower disconnect];
    
    // Delete 60 objects
    numConfigs = 60;
    NSLog(@"****************************DELETE MANY*************************");
    NSArray *allConfigs = [leaderBucket allObjects];
    for (int i=0; i<numConfigs; i++) {
        Config *config = [allConfigs objectAtIndex:i];
        [leaderBucket deleteObject: config];
    }
    
    // Expect all objects to get deleted
    [self expectAdditions:0 deletions:numConfigs changes:0 fromLeader:leader expectAcks:YES];
    [leader.simperium save];
    XCTAssertTrue([self waitForCompletion:numConfigs/3.0 farmArray:[NSArray arrayWithObject:leader]], @"timed out (deleting many)");
    [self resetExpectations:self.farms];
    
    NSLog(@"*************************FOLLOWER RECONNECT*******************");
    // Create an offline object that isn't synced yet to make sure it doesn't get clobbered by reindexing
    Config *offlineConfig = [followerBucket insertNewObjectForKey:@"offlineConfig"];
    
    [self expectAdditions:0 deletions:numConfigs changes:0 fromLeader:leader expectAcks:NO];
    [follower connect];

    XCTAssertTrue([self waitForCompletion: numConfigs/6 farmArray:[NSArray arrayWithObject:follower]], @"timed out (deleting many)");
    NSUInteger numLeft = [[followerBucket allObjects] count];
    
    [self waitFor:1.0];
    
    // Expect 10 objects left (70-60) plus the one that was created offline
    XCTAssertTrue(numLeft == 10 + 1, @"didn't delete %luuu configs", (unsigned long)numLeft);
    
    offlineConfig = [followerBucket objectForKey:@"offlineConfig"];
    XCTAssertTrue(offlineConfig != nil, @"offline object was clobbered after re-index");
    
    NSLog(@"%@ end", self.name);
}

// TODO: add a test for 50+ additions as well
@end
