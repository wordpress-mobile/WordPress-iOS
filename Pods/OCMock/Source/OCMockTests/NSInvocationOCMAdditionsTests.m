/*
 *  Copyright (c) 2006-2014 Erik Doernenburg and contributors
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
#import "NSInvocation+OCMAdditions.h"


@implementation NSValue(OCMTestAdditions)

- (id)ocmtest_initWithLongDouble:(long double)ldbl
{
    return [self initWithBytes:&ldbl objCType:@encode(typeof(ldbl))];
}

@end


@interface NSInvocationOCMAdditionsTests : XCTestCase

@end


@implementation NSInvocationOCMAdditionsTests

- (void)testInvocationDescriptionWithNoArguments
{
	SEL selector = @selector(lowercaseString);
	NSMethodSignature *signature = [NSString instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	
	XCTAssertEqualObjects(@"lowercaseString", [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithObjectArgument
{
	SEL selector = @selector(isEqualToNumber:);
	NSMethodSignature *signature = [NSNumber instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it one argument (starts at index 2)
	NSNumber *argument = [NSNumber numberWithInt:1];
	[invocation setArgument:&argument atIndex:2];
	
	NSString *expected = [NSString stringWithFormat:@"isEqualToNumber:%d", 1];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithNSStringArgument
{
	SEL selector = @selector(isEqualToString:);
	NSMethodSignature *signature = [NSString instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it one argument (starts at index 2)
	NSString *argument = @"TEST_STRING";
	[invocation setArgument:&argument atIndex:2];
	
	NSString *expected = [NSString stringWithFormat:@"isEqualToString:@\"%@\"", @"TEST_STRING"];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithObjectArguments
{
	SEL selector = @selector(setValue:forKey:);
	NSMethodSignature *signature = [NSArray instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it two arguments
	NSNumber *argumentOne = [NSNumber numberWithInt:1];
	NSString *argumentTwo = @"TEST_STRING";
	[invocation setArgument:&argumentOne atIndex:2];
	[invocation setArgument:&argumentTwo atIndex:3];
	
	NSString *expected = [NSString stringWithFormat:@"setValue:%d forKey:@\"%@\"", 1, @"TEST_STRING"];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithArrayArgument
{
	SEL selector = @selector(addObjectsFromArray:);
	NSMethodSignature *signature = [NSMutableArray instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it one argument (starts at index 2)
	NSArray *argument = [NSArray arrayWithObject:@"TEST_STRING"];
	[invocation setArgument:&argument atIndex:2];
	
	NSString *expected = [NSString stringWithFormat:@"addObjectsFromArray:%@", [argument description]];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithIntArgument
{
	SEL selector = @selector(initWithInt:);
	NSMethodSignature *signature = [NSNumber instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it an argument
	int argumentOne = 1;
	[invocation setArgument:&argumentOne atIndex:2];
	
	NSString *expected = [NSString stringWithFormat:@"initWithInt:%d", 1];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithUnsignedIntArgument
{
	SEL selector = @selector(initWithUnsignedInt:);
	NSMethodSignature *signature = [NSNumber instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it an argument
	unsigned int argumentOne = 1;
	[invocation setArgument:&argumentOne atIndex:2];
	
	NSString *expected = [NSString stringWithFormat:@"initWithUnsignedInt:%d", 1];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithBoolArgument
{
	SEL selector = @selector(initWithBool:);
	NSMethodSignature *signature = [NSNumber instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it an argument
	BOOL argumentOne = TRUE;
	[invocation setArgument:&argumentOne atIndex:2];
	
	NSString *expected = [NSString stringWithFormat:@"initWithBool:YES"];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithCharArgument
{
	SEL selector = @selector(initWithChar:);
	NSMethodSignature *signature = [NSNumber instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it an argument
	char argumentOne = 'd';
	[invocation setArgument:&argumentOne atIndex:2];
	
	NSString *expected = [NSString stringWithFormat:@"initWithChar:'%c'", argumentOne];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithUnsignedCharArgument
{
	SEL selector = @selector(initWithUnsignedChar:);
	NSMethodSignature *signature = [NSNumber instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it an argument
	unsigned char argumentOne = 'd';
	[invocation setArgument:&argumentOne atIndex:2];
	
	NSString *expected = [NSString stringWithFormat:@"initWithUnsignedChar:'%c'", argumentOne];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithDoubleArgument
{
	SEL selector = @selector(initWithDouble:);
	NSMethodSignature *signature = [NSNumber instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it an argument
	double argumentOne = 1;
	[invocation setArgument:&argumentOne atIndex:2];
	
	NSString *expected = [NSString stringWithFormat:@"initWithDouble:%f", argumentOne];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithFloatArgument
{
	SEL selector = @selector(initWithFloat:);
	NSMethodSignature *signature = [NSNumber instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it an argument
	float argumentOne = 1;
	[invocation setArgument:&argumentOne atIndex:2];
	
	NSString *expected = [NSString stringWithFormat:@"initWithFloat:%f", argumentOne];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithLongDoubleArgument
{
	SEL selector = @selector(ocmtest_initWithLongDouble:);
	NSMethodSignature *signature = [NSValue instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it an argument
	long double argumentOne = 1;
	[invocation setArgument:&argumentOne atIndex:2];
	
	NSString *expected = [NSString stringWithFormat:@"%@%Lf", NSStringFromSelector(selector),argumentOne];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithLongArgument
{
	SEL selector = @selector(initWithLong:);
	NSMethodSignature *signature = [NSNumber instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it an argument
	long argumentOne = 1;
	[invocation setArgument:&argumentOne atIndex:2];
	
	NSString *expected = [NSString stringWithFormat:@"initWithLong:%ld", argumentOne];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithUnsignedLongArgument
{
	SEL selector = @selector(initWithUnsignedLong:);
	NSMethodSignature *signature = [NSNumber instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it an argument
	unsigned long argumentOne = 1;
	[invocation setArgument:&argumentOne atIndex:2];
	
	NSString *expected = [NSString stringWithFormat:@"initWithUnsignedLong:%lu", argumentOne];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithLongLongArgument
{
	SEL selector = @selector(initWithLongLong:);
	NSMethodSignature *signature = [NSNumber instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it an argument
	long long argumentOne = 1;
	[invocation setArgument:&argumentOne atIndex:2];
	
	NSString *expected = [NSString stringWithFormat:@"initWithLongLong:%qi", argumentOne];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithUnsignedLongLongArgument
{
	SEL selector = @selector(initWithUnsignedLongLong:);
	NSMethodSignature *signature = [NSNumber instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it an argument
	unsigned long long argumentOne = 1;
	[invocation setArgument:&argumentOne atIndex:2];
	
	NSString *expected = [NSString stringWithFormat:@"initWithUnsignedLongLong:%qu", argumentOne];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithShortArgument
{
	SEL selector = @selector(initWithShort:);
	NSMethodSignature *signature = [NSNumber instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it an argument
	short argumentOne = 1;
	[invocation setArgument:&argumentOne atIndex:2];
	
	NSString *expected = [NSString stringWithFormat:@"initWithShort:%hi", argumentOne];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithUnsignedShortArgument
{
	SEL selector = @selector(initWithUnsignedShort:);
	NSMethodSignature *signature = [NSNumber instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it an argument
	unsigned short argumentOne = 1;
	[invocation setArgument:&argumentOne atIndex:2];

	NSString *expected = [NSString stringWithFormat:@"initWithUnsignedShort:%hu", argumentOne];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithStructArgument
{
	SEL selector = @selector(substringWithRange:);
	NSMethodSignature *signature = [NSString instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it an argument
	NSRange range;
	range.location = 2;
	range.length = 4;
	[invocation setArgument:&range atIndex:2];
	
	NSString *expected = @"substringWithRange:(NSRange: {2, 4})";
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithCStringArgument
{
	SEL selector = @selector(initWithUTF8String:);
	NSMethodSignature *signature = [NSString instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it an argument
	NSString *string = @"A string that is longer than 100 characters. 123456789 123456789 123456789 123456789 123456789 123456789";
	const char *cString = [string UTF8String]; 
	[invocation setArgument:&cString atIndex:2];

	NSString *expected = [NSString stringWithFormat:@"initWithUTF8String:\"%@...\"", [string substringToIndex:100]];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithSelectorArgument
{
	SEL selector = @selector(respondsToSelector:);
	NSMethodSignature *signature = [NSString instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it an argument
	SEL selectorValue = @selector(testInvocationDescriptionWithSelectorArgument);
	[invocation setArgument:&selectorValue atIndex:2];
	
	NSString *expected = [NSString stringWithFormat:@"respondsToSelector:@selector(%@)", NSStringFromSelector(selectorValue)];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

- (void)testInvocationDescriptionWithPointerArgument
{
	SEL selector = @selector(initWithBytes:length:);
	NSMethodSignature *signature = [NSData instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it an argument
	NSData *data = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];
	const void *bytes = [[@"foo" dataUsingEncoding:NSUTF8StringEncoding] bytes];
	NSUInteger length = [data length];
	[invocation setArgument:&bytes atIndex:2];
	[invocation setArgument:&length atIndex:3];
	
	NSString *expected1 = [NSString stringWithFormat:@"initWithBytes:"];
	NSString *expected2 = [NSString stringWithFormat:@"length:%lu", (unsigned long)length];
	NSString *invocationDescription = [invocation invocationDescription];
	XCTAssertTrue([invocationDescription rangeOfString:expected1].length > 0, @"");
	XCTAssertTrue([invocationDescription rangeOfString:expected2].length > 0, @"");
}

- (void)testInvocationDescriptionWithNilArgument
{
	SEL selector = @selector(initWithString:);
	NSMethodSignature *signature = [NSString instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setSelector:selector];
	// Give it an argument
	NSString *argString = nil;
	[invocation setArgument:&argString atIndex:2];
	
	NSString *expected = [NSString stringWithFormat:@"initWithString:nil"];
	XCTAssertEqualObjects(expected, [invocation invocationDescription], @"");
}

@end
