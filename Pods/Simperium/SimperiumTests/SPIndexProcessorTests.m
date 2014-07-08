//
//  SPIndexProcessorTests.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 6/18/14.
//  Copyright (c) 2014 Simperium. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XCTestCase+Simperium.h"
#import "MockSimperium.h"
#import "SPBucket+Internals.h"
#import "SPGhost.h"
#import "SPIndexProcessor.h"
#import "SPStorageProvider.h"
#import "Config.h"

#import "NSString+Simperium.h"
#import "JSONKit+Simperium.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static NSInteger const SPNumberOfEntities   = 100;
static NSInteger const SPKeyLength          = 10;
static NSInteger const SPLogLength          = 50;


#pragma mark ====================================================================================
#pragma mark SPIndexProcessorTests
#pragma mark ====================================================================================

@interface SPIndexProcessorTests : XCTestCase

@end

@implementation SPIndexProcessorTests

- (void)testProcessVersionsWithoutPreexistingObjects {
    
    // ===================================================================================================
	// Helpers
    // ===================================================================================================
    //
	MockSimperium* s                = [MockSimperium mockSimperium];
	SPBucket* bucket                = [s bucketForName:NSStringFromClass([Config class])];
    
    
    // ===================================================================================================
    // Prepare Remote Entites Message (x SPNumberOfEntities)
    // ===================================================================================================
    //
    NSMutableArray *versions        = [NSMutableArray array];
    NSMutableDictionary *versionMap = [NSMutableDictionary dictionary];
    NSString *endVersion            = @"10";
    
    for (NSInteger i = 0; i < SPNumberOfEntities; ++i) {
    
        // Random Key
        NSString *key           = [NSString sp_randomStringOfLength:SPKeyLength];
        
        // Random Data
        NSString *log           = [NSString sp_randomStringOfLength:SPLogLength];
        NSDecimalNumber *cost   = [NSDecimalNumber decimalNumberWithString:endVersion];
        NSNumber *warp          = @(rand());
        
        // Marshall'ing
        NSDictionary *data = @{
            NSStringFromSelector(@selector(captainsLog))    : log,
            NSStringFromSelector(@selector(cost))           : cost,
            NSStringFromSelector(@selector(warpSpeed))      : warp,
        };
        
        [versions addObject:@[ key, endVersion, data ] ];
        versionMap[key] = data;
    }
    
    XCTAssertEqual(versions.count, SPNumberOfEntities, @"Error while generating versions");
    NSLog(@"<> Successfully generated versions");
    
    
    // ===================================================================================================
    // Process remote changes
    // ===================================================================================================
    //
	StartBlock();
    
    dispatch_async(bucket.processorQueue, ^{
        
        [bucket.indexProcessor processVersions:versions bucket:bucket changeHandler:^(NSString *key) {
            XCTAssert(false, @"This should not get called");
        }];
        
		dispatch_async(dispatch_get_main_queue(), ^{
			EndBlock();
		});
    });
    
	WaitUntilBlockCompletes();
    
    NSLog(@"<> Finished processing versions");
    
    
    // ===================================================================================================
    // Verify if the indexProcessor actually did its job
    // ===================================================================================================
    //
    NSArray *insertedConfigs = [bucket allObjects];
    XCTAssertEqual(insertedConfigs.count, SPNumberOfEntities, @"Error processing versions");
    
    for (Config *config in insertedConfigs) {
        
        NSDictionary *versionData       = versionMap[config.simperiumKey];
        NSString *expectedLog           = versionData[NSStringFromSelector(@selector(captainsLog))];
        NSDecimalNumber *expectedCost   = versionData[NSStringFromSelector(@selector(cost))];
        NSNumber *expectedWarp          = versionData[NSStringFromSelector(@selector(warpSpeed))];
        
        XCTAssert([config isKindOfClass:[Config class]],            @"Invalid object kind");
        XCTAssertEqualObjects(config.captainsLog, expectedLog,      @"1Invalid Log");
        XCTAssertEqualObjects(config.cost, expectedCost,            @"Invalid Cost");
        XCTAssertEqualObjects(config.warpSpeed, expectedWarp,       @"Invalid Warp");
        XCTAssertEqualObjects(config.ghost.version, endVersion,     @"Invalid Ghost Version");
        XCTAssertEqualObjects(config.ghost.memberData, versionData, @"Invalid Ghost MemberData");
    }
}

- (void)testProcessVersionsWithExistingObjectsAndZeroLocalPendingChanges {
    
    // ===================================================================================================
	// Testing values!
    // ===================================================================================================
    //
    NSString *originalLog           = @"1111 Captains Log";
    NSNumber *originalWarp          = @(29);
    NSDecimalNumber *originalCost   = [NSDecimalNumber decimalNumberWithString:@"100"];
    NSDate *originalDate            = [NSDate date];
    
    NSString *newRemoteLog          = @"2222 Captains Log";
    NSNumber *newRemoteWarp         = @(10);
    NSDecimalNumber *newRemoteCost  = [NSDecimalNumber decimalNumberWithString:@"300"];
    NSDate *newRemoteDate           = [NSDate date];
    
    
    // ===================================================================================================
	// Helpers
    // ===================================================================================================
    //
	MockSimperium* s                = [MockSimperium mockSimperium];
	SPBucket* bucket                = [s bucketForName:NSStringFromClass([Config class])];
	id<SPStorageProvider> storage   = bucket.storage;
    
    
    // ===================================================================================================
	// Insert Configs
    // ===================================================================================================
    //
    NSMutableArray *configs = [NSMutableArray array];
    
    for (NSInteger i = 0; i < SPNumberOfEntities; ++i) {
        Config* config                  = [storage insertNewObjectForBucketName:bucket.name simperiumKey:nil];
        config.captainsLog              = originalLog;
        config.warpSpeed                = originalWarp;
        config.cost                     = originalCost;
        config.date                     = originalDate;
        
        // Manually Intialize SPGhost: we're not relying on the backend to confirm these additions!
        NSMutableDictionary *memberData = [config.dictionary mutableCopy];
        SPGhost *ghost                  = [[SPGhost alloc] initWithKey:config.simperiumKey memberData:memberData];
        ghost.version                   = @"1";
        config.ghost                    = ghost;
        config.ghostData                = [memberData sp_JSONString];
        
        [configs addObject:config];
    }
    
	[storage save];
    
    NSLog(@"<> Successfully inserted Config object");
    
    
    // ===================================================================================================
    // Prepare Remote Entity Message
    // ===================================================================================================
    //
    NSMutableArray *versions        = [NSMutableArray array];
    NSMutableDictionary *versionMap = [NSMutableDictionary dictionary];
    NSString *endVersion            = @"930";
    
    NSDictionary *data              = @{
        NSStringFromSelector(@selector(captainsLog))    : newRemoteLog,
        NSStringFromSelector(@selector(cost))           : newRemoteCost,
        NSStringFromSelector(@selector(warpSpeed))      : newRemoteWarp,
        NSStringFromSelector(@selector(date))           : [newRemoteDate description]
    };
    
    for (Config *config in configs) {
        
        [versions addObject:@[ config.simperiumKey, endVersion, data ] ];
        versionMap[config.simperiumKey] = data;
    }
    
    NSLog(@"<> Successfully generated versions");
    
    
    // ===================================================================================================
    // Process remote changes
    // ===================================================================================================
    //
	StartBlock();
    
    dispatch_async(bucket.processorQueue, ^{
        
        [bucket.indexProcessor processVersions:versions bucket:bucket changeHandler:^(NSString *key) {
            XCTAssert(false, @"This should not get called");
        }];
        
		dispatch_async(dispatch_get_main_queue(), ^{
			EndBlock();
		});
    });
    
	WaitUntilBlockCompletes();
    
    NSLog(@"<> Finished processing versions");
    
    
    // ===================================================================================================
    // Verify if the indexProcessor actually did its job
    // ===================================================================================================
    //
    [storage refaultObjects:configs];
    
    for (Config *config in configs) {
        NSDictionary *versionData = versionMap[config.simperiumKey];
        
        XCTAssertEqualObjects(config.captainsLog, newRemoteLog,     @"Invalid Log");
        XCTAssertEqualObjects(config.cost, newRemoteCost,           @"Invalid Cost");
        XCTAssertEqualObjects(config.warpSpeed, newRemoteWarp,      @"Invalid Warp");
        XCTAssertEqualObjects(config.ghost.version, endVersion,     @"Invalid Ghost Version");
        XCTAssertEqualObjects(config.ghost.memberData, versionData, @"Invalid Ghost MemberData");
    }
}

- (void)testProcessVersionsWithExistingObjectsAndLocalPendingChangesSucceedsRebasing {
    
    // ===================================================================================================
	// Testing values!
    // ===================================================================================================
    //
    NSString *originalLog               = @"Original Captains Log";
    NSNumber *originalWarp              = @(29);
    NSDecimalNumber *originalCost       = [NSDecimalNumber decimalNumberWithString:@"100"];
    
    NSString *localPendingLog           = @"Something Original Captains Log";
    NSNumber *localPendingWarp          = @(31337);
    NSDecimalNumber *localPendingCost   = [NSDecimalNumber decimalNumberWithString:@"900"];
    
    NSString *newRemoteLog              = @"Remote Original Captains Log Suffixed";
    NSNumber *newRemoteWarp             = @(10);
    NSDecimalNumber *newRemoteCost      = [NSDecimalNumber decimalNumberWithString:@"300"];
    
    // We expect the strings to be merged. Numbers, on the other side, should remain with the local pending values.
    NSString *expectedLog               = @"Remote Something Original Captains Log Suffixed";
    NSNumber *expectedWarp              = localPendingWarp;
    NSDecimalNumber *expectedCost       = localPendingCost;
    
    
    // ===================================================================================================
	// Helpers
    // ===================================================================================================
    //
	MockSimperium* s                    = [MockSimperium mockSimperium];
	SPBucket* bucket                    = [s bucketForName:NSStringFromClass([Config class])];
	id<SPStorageProvider> storage       = bucket.storage;
    
    
    // ===================================================================================================
	// Insert Config
    // ===================================================================================================
    //
    Config* config                      = [storage insertNewObjectForBucketName:bucket.name simperiumKey:nil];
    config.captainsLog                  = originalLog;
    config.warpSpeed                    = originalWarp;
    config.cost                         = originalCost;
    
    
    // ===================================================================================================
    // Manually Intialize SPGhost: we're not relying on the backend to confirm these additions!
    // ===================================================================================================
    //
    NSMutableDictionary *memberData     = [config.dictionary mutableCopy];
    SPGhost *ghost                      = [[SPGhost alloc] initWithKey:config.simperiumKey memberData:memberData];
    ghost.version                       = @"1";
    config.ghost                        = ghost;
    config.ghostData                    = [memberData sp_JSONString];
    
	[storage save];
    
    NSLog(@"<> Successfully inserted Config object");
    
    
    // ===================================================================================================
    // Prepare Remote Versions Message
    // ===================================================================================================
    //
    NSString *endVersion    = [NSString stringWithFormat:@"%d", config.ghost.version.intValue + 1];
    
    NSDictionary *data      = @{
        NSStringFromSelector(@selector(captainsLog))    : newRemoteLog,
        NSStringFromSelector(@selector(cost))           : newRemoteCost,
        NSStringFromSelector(@selector(warpSpeed))      : newRemoteWarp,
    };
    
    NSArray *versions       = @[ @[ config.simperiumKey, endVersion, data ] ];
    
    NSLog(@"<> Successfully generated versions");
    
    
    // ===================================================================================================
    // Set local pending changes
    // ===================================================================================================
    //
    config.captainsLog  = localPendingLog;
    config.warpSpeed    = localPendingWarp;
    config.cost         = localPendingCost;
    
    [storage save];
    
    
    // ===================================================================================================
    // Process remote changes
    // ===================================================================================================
    //
	StartBlock();
    
    dispatch_async(bucket.processorQueue, ^{
        
        [bucket.indexProcessor processVersions:versions bucket:bucket changeHandler:^(NSString *key) {
            XCTAssertEqualObjects(key, config.simperiumKey, @"Invalid key received");
        }];
        
		dispatch_async(dispatch_get_main_queue(), ^{
			EndBlock();
		});
    });
    
	WaitUntilBlockCompletes();
    
    NSLog(@"<> Finished processing versions");
    
    
    // ===================================================================================================
    // Verify if the indexProcessor actually did its job
    // ===================================================================================================
    //
    
    [storage refaultObjects:@[config]];
    
    XCTAssertEqualObjects(config.captainsLog, expectedLog,  @"Invalid Log");
    XCTAssertEqualObjects(config.cost, expectedCost,        @"Invalid Cost");
    XCTAssertEqualObjects(config.warpSpeed, expectedWarp,   @"Invalid Warp");
    XCTAssertEqualObjects(config.ghost.version, endVersion, @"Invalid Ghost Version");
    XCTAssertEqualObjects(config.ghost.memberData, data,    @"Invalid Ghost MemberData");
}

- (void)testProcessVersionsWithExistingObjectsAndLocalPendingChangesFailsRebasingAndFavorsLocalData {
    
    // ===================================================================================================
	// Testing values!
    // ===================================================================================================
    //
    NSString *originalLog           = @"Original Captains Log";
    NSString *localPendingLog       = @"Local Captains Log";
    NSString *newRemoteLog          = @"Remote Captains Log";
    NSString *expectedLog           = localPendingLog;
    
    
    // ===================================================================================================
	// Helpers
    // ===================================================================================================
    //
	MockSimperium* s                = [MockSimperium mockSimperium];
	SPBucket* bucket                = [s bucketForName:NSStringFromClass([Config class])];
	id<SPStorageProvider> storage   = bucket.storage;
    
    
    // ===================================================================================================
	// Insert Config
    // ===================================================================================================
    //
    Config* config                  = [storage insertNewObjectForBucketName:bucket.name simperiumKey:nil];
    config.captainsLog              = originalLog;
    
    
    // ===================================================================================================
    // Manually Intialize SPGhost: we're not relying on the backend to confirm these additions!
    // ===================================================================================================
    //
    NSMutableDictionary *memberData = [config.dictionary mutableCopy];
    SPGhost *ghost                  = [[SPGhost alloc] initWithKey:config.simperiumKey memberData:memberData];
    ghost.version                   = @"1";
    config.ghost                    = ghost;
    config.ghostData                = [memberData sp_JSONString];
    
	[storage save];
    
    NSLog(@"<> Successfully inserted Config object");
    
    
    // ===================================================================================================
    // Prepare Remote Entity Message
    // ===================================================================================================
    //
    NSString *endVersion    = [NSString stringWithFormat:@"%d", config.ghost.version.intValue + 1];
    
    NSDictionary *data      = @{
        NSStringFromSelector(@selector(captainsLog)) : newRemoteLog,
    };
    
    NSArray *versions       = @[ @[ config.simperiumKey, endVersion, data ] ];
    
    NSLog(@"<> Successfully generated versions");
    
    
    // ===================================================================================================
    // Add local pending changes
    // ===================================================================================================
    //
    config.captainsLog  = localPendingLog;
    
    [storage save];
    
    
    // ===================================================================================================
    // Process remote changes
    // ===================================================================================================
    //
	StartBlock();
    
    dispatch_async(bucket.processorQueue, ^{
        
        [bucket.indexProcessor processVersions:versions bucket:bucket changeHandler:^(NSString *key) {
            XCTAssertEqualObjects(key, config.simperiumKey, @"Invalid key received");
        }];
        
		dispatch_async(dispatch_get_main_queue(), ^{
			EndBlock();
		});
    });
    
	WaitUntilBlockCompletes();
    
    NSLog(@"<> Finished processing versions");
    
    
    // ===================================================================================================
    // Verify if the indexProcessor actually did its job
    // ===================================================================================================
    //
    
    [storage refaultObjects:@[config]];
    
    XCTAssertEqualObjects(config.captainsLog, expectedLog,  @"Invalid Log");
    XCTAssertEqualObjects(config.ghost.version, endVersion, @"Invalid Ghost Version");
    XCTAssertEqualObjects(config.ghost.memberData, data,    @"Invalid Ghost MemberData");
}

@end
