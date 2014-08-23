//
//  SimperiumBasicTests.m
//  SimperiumBasicTests
//
//  Created by Michael Johnston on 11-04-19.
//  Copyright 2011 Simperium. All rights reserved.
//

#import "SimperiumTests.h"
#import "Config.h"
#import "Farm.h"
#import "SPBucket+Internals.h"
#import "DiffMatchPatch.h"


@interface SimperiumBasicTests : SimperiumTests

@end

@implementation SimperiumBasicTests

- (void)testAuth
{
    NSLog(@"%@ start", self.name);
    XCTAssertTrue(self.token.length > 0, @"");
    NSLog(@"token is %@", self.token);
    NSLog(@"%@ end", self.name);
}

- (void)testAddingSingleObject
{
    NSLog(@"%@ start", self.name);
    [self createAndStartFarms];
    
    // Leader sends an object to followers
    Farm *leader = self.farms[0];
    [self connectFarms];
    
    NSNumber *refWarpSpeed = [NSNumber numberWithInt:2];
    SPBucket *leaderBucket = [leader.simperium bucketForName:[Config entityName]];
    leaderBucket.delegate = leader;
    leader.config = [leaderBucket insertNewObject];
    [leader.config setValue:refWarpSpeed forKey:@"warpSpeed"];
    //leader.config.warpSpeed = refWarpSpeed;
    [leader.simperium save];
    [self expectAdditions:1 deletions:0 changes:0 fromLeader:leader expectAcks:YES];
    XCTAssertTrue([self waitForCompletion], @"timed out");
//    STAssertTrue([leader.config.warpSpeed isEqualToNumber: refWarpSpeed], @"");
    XCTAssertTrue([[leader.config valueForKey:@"warpSpeed"] isEqualToNumber: refWarpSpeed], @"");
    
    // This is failing for the JSON case because the follower farms don't know what bucket to start listening
    // to. This can be worked around by adding a special prep method to farms. However they'll still fail because
    // I need to add dynamic schema support to the REMOTE ADD and REMOTE MODIFY cases as well, so that followers
    // can consruct their schemas as new data comes off the wire.
    
    [self ensureFarmsEqual:self.farms entityName:[Config entityName]];

    NSLog(@"%@ end", self.name); 
}

- (void)testDeletingSingleObject
{
    NSLog(@"%@ start", self.name);
    [self createAndStartFarms];

    // Leader sends an object to followers, then removes it
    Farm *leader = self.farms[0];
    [self connectFarms];
	
    SPBucket *bucket = [leader.simperium bucketForName:[Config entityName]];
    leader.config = [bucket insertNewObject];
    leader.config.warpSpeed = [NSNumber numberWithInt:2];
	leader.config.captainsLog = [NSString stringWithFormat:@"%@", [NSDate date]];
    [leader.simperium save];

    NSString *configKey = [leader.config.simperiumKey copy];
	[self expectAdditions:1 deletions:0 changes:0 fromLeader:leader expectAcks:YES];
	XCTAssertTrue([self waitForCompletion], @"timed out (adding)");

	[bucket deleteObject:leader.config];
	[leader.simperium save];
	
	[self resetExpectations:self.farms];
    [self expectAdditions:0 deletions:1 changes:0 fromLeader:leader expectAcks:YES];
    XCTAssertTrue([self waitForCompletion], @"timed out (deleting)");
    
    int i=0;
    for (Farm *farm in self.farms) {
        farm.config = (Config *)[[farm.simperium bucketForName:[Config entityName]] objectForKey:configKey];
        XCTAssertNil(farm.config, @"config %d wasn't deleted: %@", i, farm.config);
        i += 1;
    }

    NSLog(@"%@ end", self.name);
}

- (void)testChangesToSingleObject
{
    NSLog(@"%@ start", self.name);
    [self createAndStartFarms];

    // Leader sends an object to followers, then changes multiple fields
    Farm *leader = self.farms[0];
    [self connectFarms];
    [self waitFor:1.0];
    
    leader.config = [[leader.simperium bucketForName:[Config entityName]] insertNewObject];
    leader.config.warpSpeed = [NSNumber numberWithInt:2];
    leader.config.captainsLog = @"Hi";
    leader.config.shieldPercent = [NSNumber numberWithFloat:3.14];
    leader.config.cost = [NSDecimalNumber decimalNumberWithString:@"3.00"];
    [leader.simperium save];
    [self expectAdditions:1 deletions:0 changes:0 fromLeader:leader expectAcks:YES];
    XCTAssertTrue([self waitForCompletion], @"timed out (adding)");
    XCTAssertNotNil(leader.config.ghostData, @"");

    NSNumber *refWarpSpeed = [NSNumber numberWithInt:4];
    NSString *refCaptainsLog = @"Hi!!!";
    NSNumber *refShieldPercent = [NSNumber numberWithFloat:2.718];
    NSDecimalNumber *refCost = [NSDecimalNumber decimalNumberWithString:@"4.00"];
    leader.config.warpSpeed = refWarpSpeed;
    leader.config.captainsLog = refCaptainsLog;
    leader.config.shieldPercent = refShieldPercent;
    leader.config.cost = refCost;
    [leader.simperium save];
    [self expectAdditions:0 deletions:0 changes:1 fromLeader:leader expectAcks:YES];
    XCTAssertTrue([self waitForCompletion], @"timed out (changing)");
    
    XCTAssertTrue([refWarpSpeed isEqualToNumber: leader.config.warpSpeed], @"");
    XCTAssertTrue([refCaptainsLog isEqualToString: leader.config.captainsLog], @"");
    XCTAssertTrue([refShieldPercent isEqualToNumber: leader.config.shieldPercent], @"");
    XCTAssertTrue([refCost isEqualToNumber: leader.config.cost], @"");

    [self ensureFarmsEqual:self.farms entityName:[Config entityName]];
    NSLog(@"%@ end", self.name); 
}

- (void)testPendingChange
{
    NSLog(@"%@ start", self.name);
    [self createAndStartFarms];

    // Leader sends an object to followers, then changes multiple fields
    Farm *leader = self.farms[0];
    [self connectFarms];
    
    [self waitFor:4];
    
	SPBucket *entityBucket = [leader.simperium bucketForName:[Config entityName]];
    leader.config = [entityBucket insertNewObject];
    leader.config.warpSpeed = [NSNumber numberWithInt:2];
    leader.config.captainsLog = @"Hi";
    leader.config.shieldPercent = [NSNumber numberWithFloat:3.14];
    [leader.simperium save];
    [self expectAdditions:1 deletions:0 changes:0 fromLeader:leader expectAcks:YES];
    
    // Wait just enough time for the change to be sent, but not enough time for an ack to come back
	// Dispatch a blocking no-op in the bucket!
	dispatch_sync(entityBucket.processorQueue, ^{ });
	
    // Now change right away without waiting for the object insertion to be acked
    NSNumber *refWarpSpeed = [NSNumber numberWithInt:4];
    NSString *refCaptainsLog = @"Hi!!!";
    NSNumber *refShieldPercent = [NSNumber numberWithFloat:2.718];
    leader.config.warpSpeed = refWarpSpeed;
    leader.config.captainsLog = refCaptainsLog;
    leader.config.shieldPercent = refShieldPercent;
    [leader.simperium save];
    [self expectAdditions:0 deletions:0 changes:1 fromLeader:leader expectAcks:YES];
    XCTAssertTrue([self waitForCompletion], @"timed out (changing)");
    
    XCTAssertTrue([refWarpSpeed isEqualToNumber: leader.config.warpSpeed], @"");
    XCTAssertTrue([refCaptainsLog isEqualToString: leader.config.captainsLog], @"");
    XCTAssertTrue([refShieldPercent isEqualToNumber: leader.config.shieldPercent], @"");
    [self ensureFarmsEqual:self.farms entityName:[Config entityName]];
    NSLog(@"%@ end", self.name);
}

- (void)testObjectVersions
{
    NSLog(@"%@ start", self.name);
    [self createAndStartFarms];
    
    // Leader sends an object to followers, then changes a string repeatedly
    Farm *leader = self.farms[0];
    [self connectFarms];
    
    int changeNumber = 0;
    NSString *refString = [NSString stringWithFormat:@"%d", changeNumber];
    SPBucket *bucket = [leader.simperium bucketForName:[Config entityName]];
    leader.config = [bucket insertNewObject];
    leader.config.captainsLog = refString;
    [leader.simperium save];
    [self expectAdditions:1 deletions:0 changes:0 fromLeader:leader expectAcks:YES];
    XCTAssertTrue([self waitForCompletion], @"timed out (adding)");

    int numChanges = 11;
    for (changeNumber=1; changeNumber<numChanges+1; changeNumber++) {
        [self expectAdditions:0 deletions:0 changes:1 fromLeader:leader expectAcks:YES];
        refString = [NSString stringWithFormat:@"%@.%d", refString, changeNumber];
        leader.config.captainsLog = [NSString stringWithFormat:@"%@.%d", leader.config.captainsLog, changeNumber];
        [leader.simperium save];
        XCTAssertTrue([self waitForCompletion], @"timed out (changing)");
    }
    
    // Request object versions
    leader.expectedVersions = 10;
    [bucket requestVersions:10 key:leader.config.simperiumKey];
    XCTAssertTrue([self waitForCompletion], @"timed out (changing)");

    NSLog(@"%@ end", self.name);
}

@end
