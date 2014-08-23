//
//  XCTestCase+Simperium.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 11/12/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "XCTestCase+Simperium.h"

@implementation XCTestCase (Simperium)

- (void)waitFor:(NSTimeInterval)seconds {
    NSDate* timeoutDate = [NSDate dateWithTimeIntervalSinceNow:seconds];
    NSLog(@"Waiting for %f seconds...", seconds);
	do {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
		if ([timeoutDate timeIntervalSinceNow] < 0.0) {
			break;
        }
	} while (YES);
}

@end
