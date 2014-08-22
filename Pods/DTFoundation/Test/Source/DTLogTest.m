//
//  DTLogTest.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 22.07.14.
//  Copyright (c) 2014 Cocoanetics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "DTLog.h"

@interface DTLogTest : XCTestCase

@end

@implementation DTLogTest

- (void)setUp
{
    [super setUp];
	
	// set standard log handler that logs to ASL
	DTLogSetLoggerBlock(^(NSUInteger logLevel, NSString *fileName, NSUInteger lineNumber, NSString *methodName, NSString *format, ...)
	{
		va_list args;
		va_start(args, format);
		
		DTLogMessagev(logLevel, format, args);
		
		va_end(args);
	});
	
	// cause all levels to be handled
	DTLogSetLogLevel(DTLogLevelDebug);
}

- (void)_testLogLevel:(DTLogLevel)level
{
	__block NSUInteger calledLevel;
	__block NSString *calledFileName;
	__block NSString *calledMethodName;
	__block NSString *calledMessage;
	
	DTLogSetLoggerBlock(^(NSUInteger logLevel, NSString *fileName, NSUInteger lineNumber, NSString *methodName, NSString *format, ...) {
		calledLevel = logLevel;
		calledFileName = fileName;
		calledMethodName = methodName;
		calledMessage = format;
	});
	
	NSString *errorMsg = @"Test Message, ignore";
	DTLogCallHandlerIfLevel(level, errorMsg);
	
	XCTAssertEqual(calledLevel, level, @"Incorrect log level for error message");
	
	NSString *localFileName = [[NSString stringWithUTF8String:__FILE__] lastPathComponent];
	XCTAssert([calledFileName isEqualToString:localFileName], @"Wrong file name logged");
	
	NSString *currentMethod = [NSString stringWithUTF8String:__PRETTY_FUNCTION__];
	XCTAssert([calledMethodName isEqualToString:currentMethod], @"Wrong method name logged");
	
	XCTAssert([calledMessage isEqualToString:errorMsg], @"Wrong error message logged");
}


- (void)testLogLevelEmergency
{
	[self _testLogLevel:DTLogLevelEmergency];
}

- (void)testLogLevelAlert
{
	[self _testLogLevel:DTLogLevelAlert];
}

- (void)testLogLevelError
{
	[self _testLogLevel:DTLogLevelError];
}

- (void)testLogLevelWarning
{
	[self _testLogLevel:DTLogLevelWarning];
}

- (void)testLogLevelNotice
{
	[self _testLogLevel:DTLogLevelNotice];
}

- (void)testLogLevelInfo
{
	[self _testLogLevel:DTLogLevelInfo];
}

- (void)testLogLevelDebug
{
	[self _testLogLevel:DTLogLevelDebug];
}


/**
 // does not work on Travis-CI, I think because of xctool
 
- (void)testLogRetrieval
{
	NSString *errorMsg = @"Test Message, ignore";
	DTLogError(errorMsg);
	DTLogWarning(errorMsg);
	
	NSArray *array = DTLogGetMessages();
	
	XCTAssertEqual([array count], 2, @"There should be one message");
	NSDictionary *message = array[0];
	
	NSString *text = message[@"Message"];
	XCTAssert([text isEqualToString:errorMsg], @"Message text should be '%@'", errorMsg);
	
	DTLogLevel level = [message[@"Level"] integerValue];
	XCTAssertEqual(level, DTLogLevelError, @"Log level should be error");
	
	message = array[1];
	
	text = message[@"Message"];
	XCTAssert([text isEqualToString:errorMsg], @"Message text should be '%@'", errorMsg);
	
	level = [message[@"Level"] integerValue];
	XCTAssertEqual(level, DTLogLevelWarning, @"Log level should be notice");
}
 */

@end
