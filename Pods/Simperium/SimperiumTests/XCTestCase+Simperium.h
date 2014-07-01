//
//  XCTestCase+Simperium.h
//  Simperium
//
//  Created by Jorge Leandro Perez on 11/12/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface XCTestCase (Simperium)
- (void)waitFor:(NSTimeInterval)seconds;
@end

// Asynchronous Testing Helpers
// Ref: http://dadabeatnik.wordpress.com/2013/09/12/xcode-and-asynchronous-unit-testing/

// Macro - Set the flag for block completion
#define StartBlock() __block BOOL waitingForBlock = YES

// Macro - Set the flag to stop the loop
#define EndBlock() waitingForBlock = NO

// Macro - Wait and loop until flag is set
#define WaitUntilBlockCompletes() \
do { \
	while(waitingForBlock) { [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]; } \
} while(0)
