//
//  SimperiumBinaryTests.m
//  Simperium
//
//  Created by Michael Johnston on 12-07-19.
//  Copyright (c) 2012 Simperium. All rights reserved.
//

#import "SimperiumTests.h"
#import "Farm.h"
#import "SPS3Manager.h"


@interface SimperiumBinaryTests : SimperiumTests

@end

@implementation SimperiumBinaryTests

- (void)setUp
{
    [super setUp];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    if(![[NSFileManager defaultManager] createDirectoryAtPath: [paths objectAtIndex:0] withIntermediateDirectories:YES attributes:nil error:NULL])
        NSLog(@"Error: Create folder failed %@", NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES));
}

- (NSData *)randomDataWithBytes: (NSUInteger)length
{
    NSMutableData *mutableData = [NSMutableData dataWithCapacity: length];
    for (unsigned int i = 0; i < length; i++) {
        NSInteger randomBits = arc4random();
        [mutableData appendBytes: (void *) &randomBits length: 1];
    } return mutableData;
}

- (void)testSmallBinaryFile
{
    NSLog(@"%@ start", self.name);
    [self createAndStartFarms];
        
    // Leader sends an object to followers
    Farm *leader = [farms objectAtIndex:0];
    leader.simperium.binaryManager = [[SPS3Manager alloc] initWithSimperium: leader.simperium];
    [leader.simperium.binaryManager addDelegate:leader];
    [self connectFarms];
    [self waitFor:2];
    [leader.simperium.binaryManager setupAuth:leader.simperium.user];
    [self waitFor:2];
    
    SPBucket *leaderBucket = [leader.simperium bucketForName:@"Config"];
    leader.config = [leaderBucket insertNewObject];
    NSData *data = [self randomDataWithBytes:8096];
    [leader.simperium addBinary:data toObject:leader.config bucketName:@"Config" attributeName:@"binaryFile"];
    [leader.simperium save];
    [self expectAdditions:1 deletions:0 changes:0 fromLeader:leader expectAcks:YES];
    STAssertTrue([self waitForCompletion], @"timed out");
    //    STAssertTrue([leader.config.warpSpeed isEqualToNumber: refWarpSpeed], @"");
    
    [self ensureFarmsEqual:farms entityName:@"Config"];
    
    NSLog(@"%@ end", self.name); 
}


@end
