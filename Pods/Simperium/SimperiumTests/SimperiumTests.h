//
//  SimperiumTests.h
//  SimperiumTests
//
//  Created by Michael Johnston on 11-04-19.
//  Copyright 2011 Simperium. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "Simperium.h"
#import "TestParams.h"


@class Farm;

@interface SimperiumTests : XCTestCase <SimperiumDelegate>

@property (nonatomic, strong) NSMutableArray	*farms;
@property (nonatomic, copy)   NSString			*token;
@property (nonatomic, assign) BOOL				done;

- (void)waitFor:(NSTimeInterval)seconds;
- (BOOL)farmsDone:(NSArray *)farmArray;
- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSecs farmArray:(NSArray *)farmArray;
- (BOOL)waitForCompletion;
- (Farm *)createFarm:(NSString *)label;
- (void)ensureFarmsEqual: (NSArray *)farmArray entityName:(NSString *)entityName;
- (void)createFarms;
- (void)startFarms;
- (void)createAndStartFarms;
- (void)connectFarms;
- (void)disconnectFarms;
- (void)expectAdditions:(int)additions deletions:(int)deletions changes:(int)changes fromLeader:(Farm *)leader expectAcks:(BOOL)expectAcks;
- (void)resetExpectations:(NSArray *)farmArray;

@end
