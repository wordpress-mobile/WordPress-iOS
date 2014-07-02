/*
 *  Copyright (c) 2013-2014 Erik Doernenburg and contributors
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License. You may obtain
 *  a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */

#import <XCTest/XCTest.h>
#import "OCMArg.h"

#if TARGET_OS_IPHONE
#define NSRect CGRect
#define NSZeroRect CGRectZero
#define NSMakeRect CGRectMake
#define valueWithRect valueWithCGRect
#endif

@interface OCMArgTests : XCTestCase

@end


@implementation OCMArgTests

- (void)testValueMacroCreatesCorrectValueObjects
{
    NSRange range = NSMakeRange(5, 5);
    XCTAssertEqualObjects(OCMOCK_VALUE(range), [NSValue valueWithRange:range]);
#if !(TARGET_OS_IPHONE && TARGET_RT_64_BIT)
    /* This should work everywhere but I can't get it to work on iOS 64-bit */
    XCTAssertEqualObjects(OCMOCK_VALUE((BOOL){YES}), @YES);
#endif
    XCTAssertEqualObjects(OCMOCK_VALUE(42), @42);
#if !TARGET_OS_IPHONE
    XCTAssertEqualObjects(OCMOCK_VALUE(NSZeroRect), [NSValue valueWithRect:NSZeroRect]);
#endif
    XCTAssertEqualObjects(OCMOCK_VALUE([@"0123456789" rangeOfString:@"56789"]), [NSValue valueWithRange:range]);
}

@end
