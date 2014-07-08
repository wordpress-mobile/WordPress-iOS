//
//  SimperiumAuxiliaryTests.m
//  SimperiumAuxiliaryTests
//
//  Created by Michael Johnston on 11-04-19.
//  Copyright 2011 Simperium. All rights reserved.
//

#import "SimperiumTests.h"
#import "Config.h"
#import "Farm.h"
#import "SPBucket.h"
#import "DiffMatchPatch.h"


@interface SimperiumAuxiliaryTests : SimperiumTests

@end

@implementation SimperiumAuxiliaryTests

- (void)testDMP {
    NSString *a = @"a";
    NSString *b = @"ab";
    NSString *c = @"ac";
    
    // Assorted hocus pocus ported from JS code
    NSError *error;
    DiffMatchPatch *dmp = [[DiffMatchPatch alloc] init];

    NSMutableArray * ac_diff =[dmp diff_mainOfOldString:a andNewString:c];
    NSMutableArray * ab_diff = [dmp diff_mainOfOldString:a andNewString:b];
    
    NSString *ac_diffs_delta = [dmp diff_toDelta:ac_diff];
    NSString *ab_diffs_delta = [dmp diff_toDelta:ab_diff];
    
    NSMutableArray *ac_diffs = [dmp diff_fromDeltaWithText:a andDelta:ac_diffs_delta error:&error];
    NSMutableArray *ac_patches = [dmp patch_makeFromOldString:a andDiffs:ac_diffs];
    NSLog(@"ac_diffs:%@", [ac_diffs description]);
    NSLog(@"ac_patches:%@", [ac_patches description]);

    NSMutableArray *ab_diffs = [dmp diff_fromDeltaWithText:a andDelta:ab_diffs_delta error:&error];
    NSMutableArray *ab_patches = [dmp patch_makeFromOldString:a andDiffs:ab_diffs];
    NSLog(@"ab_diffs:%@", [ab_diffs description]);
    NSLog(@"ab_patches:%@", [ab_patches description]);
    
    

    NSArray *ac_patch_apply = [dmp patch_apply:ac_patches toString:a];
    NSLog(@"ac_patch_apply: %@", [ac_patch_apply description]);
    NSString *interim_text = [[dmp patch_apply:ac_patches toString:a] objectAtIndex:0];
    NSLog(@"interim: %@, c:%@", interim_text, c);
    
    NSString *final_text = [[dmp patch_apply:ab_patches toString:interim_text] objectAtIndex:0];
    NSLog(@"final: %@", final_text);    
}

- (void)testKeyWithPeriods {
    NSLog(@"%@ start", self.name);
    
    // Leader sends an object to follower, but make follower get it from the index
    Farm *leader = [self createFarm:@"leader"];
    Farm *follower = [self createFarm:@"follower"];
    leader.expectedIndexCompletions = 1;
    [leader start];
    [leader connect];
    XCTAssertTrue([self waitForCompletion], @"timed out");
    
    NSNumber *refWarpSpeed = [NSNumber numberWithInt:2];
    leader.config = [[leader.simperium bucketForName:[Config entityName]] insertNewObjectForKey:@"key.with.periods"];
    leader.config.warpSpeed = refWarpSpeed;
    [leader.simperium save];
    leader.expectedAcknowledgments = 1;
    XCTAssertTrue([self waitForCompletion], @"timed out");
    
    // Make a change to ensure version numbers increase
    refWarpSpeed = [NSNumber numberWithInt:4];
    leader.config.warpSpeed = refWarpSpeed;
    [leader.simperium save];
    leader.expectedAcknowledgments = 1;
    XCTAssertTrue([self waitForCompletion], @"timed out (changing)");
    
    // The object was synced, now connect with the follower
    [self resetExpectations: self.farms];
    follower.expectedIndexCompletions = 1;
    [self expectAdditions:1 deletions:0 changes:0 fromLeader:leader expectAcks:NO];
	
    [follower start];
    [follower connect];
	
    XCTAssertTrue([self waitForCompletion], @"timed out");
    
    [self ensureFarmsEqual:self.farms entityName:[Config entityName]];
    NSLog(@"%@ end", self.name);
}


//- (void)testSeededData
//{
//    NSLog(@"%@ start", self.name);
//    [self createFarms];
//    
//    // Leader seeds an object
//    Farm *leader = [farms objectAtIndex:0];
//    
//    NSNumber *refWarpSpeed = [NSNumber numberWithInt:2];
//    leader.config = [NSEntityDescription insertNewObjectForEntityForName:@"Config" inManagedObjectContext:leader.managedObjectContext];
//    //leader.config.simperiumKey = @"config";
//    leader.config.warpSpeed = refWarpSpeed;
//    
//    [leader.managedObjectContext save:nil];
//    
//    // Now go online
//    leader.simperium.networkEnabled = NO;
//    
//    // Problem: the above changes are marked by simperium, but starting the farm here will clear those changes
//    // Solution? Add an alternative start: that doesn't clear?
//    [leader start];
//    leader.simperium.networkEnabled = YES;
//    [leader connect];
//
//    leader.expectedAcknowledgments = 1;
//    STAssertTrue([self waitForCompletion], @"timed out");
//        
//    // The object was synced, now check followers to see if data was fully seeded
//    for (Farm *farm in farms) {
//        if (farm == leader)
//            continue;
//        [farm start];
//        [farm connect];
//    }
//    [self resetExpectations: farms];
//    [self expectAdditions:1 deletions:0 changes:0 fromLeader:leader expectAcks:NO];
//    
//    STAssertTrue([self waitForCompletion], @"timed out");
//    
//    [self ensureFarmsEqual:farms entityName:@"Config"];
//    NSLog(@"%@ end", self.name);
//}


@end
