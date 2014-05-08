//
//  DTBlockFunctionsTest.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 02.10.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTBlockFunctionsTest.h"
#import "DTBlockFunctions.h"

@implementation DTBlockFunctionsTest

- (void)testSyncDispatch
{
	// demonstrate the normal dispatching behavior
	__block BOOL changed1 = NO;
	__block BOOL changed2 = NO;
	__block BOOL changed3 = NO;
	
	dispatch_semaphore_t sema = dispatch_semaphore_create(0);
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		[NSThread sleepForTimeInterval:1];
		
		changed1 = YES;
		
		// this should be async and thus not being picked up by the changed3 assert
		DTBlockPerformSyncIfOnMainThreadElseAsync(^{
			
			changed3 = YES;
		});
		
		// we are on a background queue here,
		dispatch_semaphore_signal(sema);
	});
	
	XCTAssertFalse(changed1, @"dispatch_async should not get executed in time");
	

	// now test functionality of the function
	
	DTBlockPerformSyncIfOnMainThreadElseAsync(^{
		
		changed2 = YES;
	});

	
	XCTAssertTrue(changed2, @"DTBlockPerformSyncIfOnMainThreadElseAsync did not get executed inline");
	
	// wait until first background queue operation is done
	dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
	
	XCTAssertFalse(changed3, @"perform should have been dispatched asynchronously");
}

@end
