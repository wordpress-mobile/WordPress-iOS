//
//  SimperiumOfflineTests.m
//  SimperiumOfflineTests
//
//  Created by Michael Johnston on 11-04-19.
//  Copyright 2011 Simperium. All rights reserved.
//

#import "SimperiumTests.h"
#import "Config.h"
#import "Farm.h"
#import "SPBucket.h"
#import "DiffMatchPatch.h"


@interface SimperiumOfflineTests : SimperiumTests

@end

@implementation SimperiumOfflineTests

- (void)testSingleOfflineStringChange
{
    NSLog(@"%@ start", self.name);

    // Leader sends an object to a follower, follower goes offline, both make changes, follower reconnects
    Farm *leader = [self createFarm:@"leader"];
    Farm *follower = [self createFarm:@"follower"];
    [leader start];
    [follower start];
    
    NSArray *farmArray = [NSArray arrayWithObjects:leader, follower, nil];
    [leader connect];
    [follower connect];
    [self waitFor:1.0];
    
    leader.config = [[leader.simperium bucketForName:[Config entityName]] insertNewObject];
    leader.config.captainsLog = @"1";
    [leader.simperium save];
    NSString *configKey = leader.config.simperiumKey;
    leader.expectedAcknowledgments = 1;
    follower.expectedAdditions = 1;
    XCTAssertTrue([self waitForCompletion: 4.0 farmArray:farmArray], @"timed out (adding)");
    [self resetExpectations: farmArray];
    [self ensureFarmsEqual:farmArray entityName:[Config entityName]];
    NSLog(@"****************************DISCONNECT*************************");
    [follower disconnect];
    
    follower.config = (Config *)[[follower.simperium bucketForName:[Config entityName]] objectForKey:configKey];
    follower.config.captainsLog = @"12";
    follower.expectedAcknowledgments = 1;
    leader.expectedChanges = 1;
    [follower.simperium save];
    
    [self waitFor:1.0];
    NSLog(@"****************************RECONNECT*************************");
    [follower connect];
    XCTAssertTrue([self waitForCompletion:4.0 farmArray:farmArray], @"timed out (changing)");
    
    // Make sure there's no residual weirdness
    [self waitFor:1.0];
    
    NSString *refString = @"12";
    XCTAssertTrue([refString isEqualToString: leader.config.captainsLog],
                 @"leader %@ != ref %@", leader.config.captainsLog, refString);
    [self ensureFarmsEqual:farmArray entityName:[Config entityName]];
    NSLog(@"%@ end", self.name); 
}


- (void)testSimultaneousOfflineStringChange
{
    NSLog(@"%@ start", self.name);
    
    // Leader sends an object to a follower, follower goes offline, both make changes, follower reconnects
    Farm *leader = [self createFarm:@"leader"];
    Farm *follower = [self createFarm:@"follower"];
    [leader start];
    [follower start];
    [leader connect];
    [follower connect];
    [self waitFor:1.5];
    
    leader.config = [[leader.simperium bucketForName:[Config entityName]] insertNewObject];
    leader.config.captainsLog = @"a";
    leader.expectedAcknowledgments = 1;
    follower.expectedAdditions = 1;
    [leader.simperium save];
    NSString *configKey = leader.config.simperiumKey;
    XCTAssertTrue([self waitForCompletion: 6.0 farmArray:self.farms], @"timed out (adding)");
    [self resetExpectations:self.farms];
    [self ensureFarmsEqual:self.farms entityName:[Config entityName]];
    [follower disconnect];
    [self waitFor:1.0];

    leader.config.captainsLog = @"ab";
    leader.expectedAcknowledgments = 1;
    [leader.simperium save];
    XCTAssertTrue([self waitForCompletion:6.0 farmArray:self.farms], @"timed out (changing)");
    [self resetExpectations:self.farms];
    
    follower.config = (Config *)[[follower.simperium bucketForName:[Config entityName]] objectForKey:configKey];
    follower.config.captainsLog = @"ac";
    follower.expectedAcknowledgments = 1;
    follower.expectedChanges = 1;
    leader.expectedChanges = 1;
    [follower.simperium save];
    [self waitFor:0.5];
    [follower connect];
    XCTAssertTrue([self waitForCompletion:6.0 farmArray:self.farms], @"timed out (changing)");
    
    // Make sure there's no residual weirdness
    [self waitFor:1.0];

    NSString *refString = @"abc";
    XCTAssertTrue([refString isEqualToString: leader.config.captainsLog],
                 @"leader %@ != ref %@", leader.config.captainsLog, refString);
    [self ensureFarmsEqual:self.farms entityName:[Config entityName]];
    NSLog(@"%@ end", self.name); 
}

- (void)testOfflineCreationAndEditing
{
    NSLog(@"%@ start", self.name);
        
    // Leader creates an object offline, changes it, then connects
    Farm *leader = [self createFarm:@"leader"];
    
    // Change URL to an invalid one to simulate airplane mode (crude)
    [leader start];
    leader.simperium.rootURL = @"http://iosunittest.simperium.com:1234/1/";
    [leader connect];

    SPBucket *bucket = [leader.simperium bucketForName:@"Config"];
    NSArray *farmArray = [NSArray arrayWithObjects:leader, nil];
    
    [self waitFor:2];
    
    leader.config = [bucket insertNewObject];
    leader.config.captainsLog = @"1";
    [leader.simperium save];
    [self waitFor:1];
    
    // Wait a tick, make a change
    leader.config.captainsLog = @"123";
    [leader.simperium save];
    [self waitFor:1];

    // Wait a tick, make a change
    leader.config.captainsLog = @"123456";
    [leader.simperium save];
    [self waitFor:1];

    // Wait a tick, make a change
    leader.config.captainsLog = @"123456 09876";
    [leader.simperium save];
    [self waitFor:1];

    
    // Again with a second object
    Config *config2 = [bucket insertNewObject];
    config2.simperiumKey = @"config2";
    config2.captainsLog = @"a";
    [leader.simperium save];
    [self waitFor:1];
    
    config2.captainsLog = @"abc";
    [leader.simperium save];
    [self waitFor:1];

    config2.captainsLog = @"abcdef";
    [leader.simperium save];
    [self waitFor:1];

    
    NSLog(@"*****RECONNECTING******");
    [leader disconnect];
    
    [self waitFor:1];
    leader.simperium.rootURL = @"https://api.simperium.com/1/";
    [leader connect];
    [self waitFor:4];

    NSString *refString = @"123456 09876";
    XCTAssertTrue([refString isEqualToString: leader.config.captainsLog],
                 @"leader %@ != ref %@", leader.config.captainsLog, refString);
    
    NSString *refString2 = @"abcdef";
    XCTAssertTrue([refString2 isEqualToString: config2.captainsLog],
                 @"leader %@ != ref %@", config2.captainsLog, refString2);
    
    [self ensureFarmsEqual:farmArray entityName:[Config entityName]];
    NSLog(@"%@ end", self.name);
}

- (void)testOfflineDeletionOfObjectWithSharedKeyBeforeInitialSync
{
    NSString *sharedKey = @"31337";
    
    // Leader: Online, please!
    Farm *leader = [self createFarm:@"Leader"];

    [leader start];
    [leader connect];
    
    [self waitFor:2.0];

    // Leader: Insert a Config Object
    SPBucket *leaderBucket      = [leader.simperium bucketForName:[Config entityName]];
    Config *leadConfig          = [leaderBucket insertNewObject];
    leadConfig.simperiumKey     = sharedKey;
    
    leader.expectedAcknowledgments = 1;
    [leader.simperium save];
    XCTAssertTrue([self waitForCompletion:4.0 farmArray:@[ leader ]], @"timed out (adding)");
    
    // Follower: While offline, Insert + Delete a Config Object, with the same key as the one used above!
    Farm *follower = [self createFarm:@"Follower"];
    [follower start];
    
    SPBucket *followerBucket    = [follower.simperium bucketForName:[Config entityName]];
    Config *followerConfig      = [followerBucket insertNewObject];
    
    followerConfig.simperiumKey = sharedKey;
    [follower.simperium save];
    
    [followerBucket deleteObject:followerConfig];
    [follower.simperium save];
    
    follower.expectedAcknowledgments = 1;
    [follower connect];
    XCTAssertTrue([self waitForCompletion:4.0 farmArray:@[ follower ]], @"timed out (adding)");
    
    XCTAssertNil([leaderBucket objectForKey:sharedKey], @"Zombie in Leader detected!");
    XCTAssertNil([followerBucket objectForKey:sharedKey], @"Zombie in Follower detected!");
}

- (void)testOfflineDeletionOfObjectWithSharedKeyAfterInitialSync
{
    NSString *sharedKey = @"31337";
    
    // Bring online both, Leader and Follower
    Farm *leader = [self createFarm:@"Leader"];
    Farm *follower = [self createFarm:@"Follower"];
    
    [leader start];
    [follower start];
    
    [leader connect];
    [follower connect];
    
    [self waitFor:2.0];
    
    // Disconnect the follower
    [follower disconnect];
    
    // Leader: Insert a Config Object
    SPBucket *leaderBucket          = [leader.simperium bucketForName:[Config entityName]];
    Config *leadConfig              = [leaderBucket insertNewObject];
    leadConfig.simperiumKey         = sharedKey;
    
    leader.expectedAcknowledgments  = 1;
    [leader.simperium save];
    XCTAssertTrue([self waitForCompletion:4.0 farmArray:@[ leader ]], @"timed out (adding)");
    
    // Follower: Add + Nuke the object, while offline
    SPBucket *followerBucket    = [follower.simperium bucketForName:[Config entityName]];
    Config *followerConfig      = [followerBucket insertNewObject];
    
    followerConfig.simperiumKey = sharedKey;
    [follower.simperium save];
    
    [followerBucket deleteObject:followerConfig];
    [follower.simperium save];
    
    follower.expectedAdditions  = 1;
    follower.expectedDeletions  = 1;
    [follower connect];
    XCTAssertTrue([self waitForCompletion:4.0 farmArray:@[ follower ]], @"timed out (adding)");
    
    XCTAssertNil([leaderBucket objectForKey:sharedKey], @"Zombie in Leader detected!");
    XCTAssertNil([followerBucket objectForKey:sharedKey], @"Zombie in Follower detected!");
}

@end
