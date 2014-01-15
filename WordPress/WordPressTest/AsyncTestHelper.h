//
//  AsyncTestHelper.h
//  WordPress
//
//  Created by Jorge Bernal on 2/12/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

extern dispatch_semaphore_t ATHSemaphore;
extern const NSTimeInterval AsyncTestCaseDefaultTimeout;

@interface AsyncTestHelper : NSObject
- (void)notify;
- (BOOL)wait;
@end

#define AsyncTestHelperWait(helper) XCTAssertTrue([helper wait], @"Async helper timed out")