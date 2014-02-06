//
//  SimperiumSimpleTests.m
//  SimperiumSimpleTests
//
//  Created by Michael Johnston on 11-04-19.
//  Copyright 2011 Simperium. All rights reserved.
//

#import "SimperiumTests.h"
#import "Config.h"
#import "Farm.h"
#import "SPBucket.h"


@interface SimperiumTypeTests : SimperiumTests

@end

@implementation SimperiumTypeTests

- (void)testDate
{
    NSLog(@"%@ start", self.name);

    Farm *leader = [self createFarm:@"leader"];
    Farm *follower = [self createFarm:@"follower"];
    [leader start];
    [follower start];
    
    NSArray *farmArray = [NSArray arrayWithObjects:leader, follower, nil];
    [leader connect];
    [follower connect];
    [self waitFor:1.0];
    
	NSString *refString = @"1";
	NSDate *refDate = [NSDate date];
	
    leader.config = [[leader.simperium bucketForName:[Config entityName]] insertNewObject];
    leader.config.captainsLog = refString;
	leader.config.date = refDate;
	
    [leader.simperium save];
    leader.expectedAcknowledgments = 1;
    follower.expectedAdditions = 1;
    XCTAssertTrue([self waitForCompletion: 4.0 farmArray:farmArray], @"timed out (adding)");
    [self resetExpectations:farmArray];
    [self ensureFarmsEqual:farmArray entityName:[Config entityName]];
    NSLog(@"****************************DISCONNECT*************************");
    [follower disconnect];
    
    
    // Make sure there's no residual weirdness
    [self waitFor:1.0];
    
	Config *followerConfig = [[follower.simperium bucketForName:[Config entityName]] objectForKey:leader.config.simperiumKey];
	
    XCTAssertTrue([refString isEqual: leader.config.captainsLog],
				  @"leader %@ != ref %@", leader.config.captainsLog, refString);
	
    XCTAssertTrue([refDate.description isEqualToString:leader.config.date.description],
				  @"leader %@ != ref %@", leader.config.date, refDate);
		
    XCTAssertTrue([refString isEqual: followerConfig.captainsLog],
				  @"follower %@ != ref %@", followerConfig.captainsLog, refString);
	
    XCTAssertTrue([refDate.description isEqualToString:leader.config.date.description],
				  @"follower %@ != ref %@", followerConfig.date, refDate);
	
    [self ensureFarmsEqual:farmArray entityName:[Config entityName]];
    NSLog(@"%@ end", self.name); 
}

@end
