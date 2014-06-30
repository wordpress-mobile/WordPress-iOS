//
//  DTVersionTest.m
//  iCatalog
//
//  Created by Rene Pirringer on 20.07.11.
//  Copyright 2011 Cocoanetics. All rights reserved.
//

#import "DTScriptingTest.h"

#import "NSScanner+DTScripting.h"
#import "DTScriptVariable.h"
#import "DTScriptExpression.h"

@implementation DTScriptingTest


- (void)_testVariable:(NSString *)text expectSuccess:(BOOL)expectSuccess
{
	NSScanner *scanner = [NSScanner scannerWithString:text];
	
	DTScriptVariable *variable = nil;
	BOOL result = [scanner scanScriptVariable:&variable];

	if (expectSuccess)
	{
		XCTAssertNotNil(variable, @"Should be able to parse '%@'", text);
		XCTAssertTrue(result, @"Parse result should be true");
	}
	else
	{
		XCTAssertNil(variable, @"Should not be able to parse '%@'", text);
		XCTAssertFalse(result, @"Parse result should be false");
	}
}

- (void)testScanVariables
{
	[self _testVariable:@"variable" expectSuccess:YES];
	[self _testVariable:@"@\"\"" expectSuccess:YES];
	[self _testVariable:@"@\"a string\"" expectSuccess:YES];
	[self _testVariable:@"@\"a string" expectSuccess:NO];
	[self _testVariable:@"12" expectSuccess:YES];
	[self _testVariable:@"12.34" expectSuccess:YES];
	[self _testVariable:@"12.34a" expectSuccess:YES];
	[self _testVariable:@"self" expectSuccess:YES];
	[self _testVariable:@"YES" expectSuccess:YES];
	[self _testVariable:@"NO" expectSuccess:YES];
	[self _testVariable:@"nil" expectSuccess:YES];
}

- (void)_textExpression:(NSString *)text expectSuccess:(BOOL)expectSuccess parameters:(NSUInteger)parameters
{
	DTScriptExpression *expression = [DTScriptExpression scriptExpressionWithString:text];

	if (expectSuccess)
	{
		XCTAssertNotNil(expression, @"Should be able to parse '%@'", text);
		XCTAssertEqual(parameters, [expression.parameters count], @"Number of parameters should be %lu in expression '%@'", (unsigned long)parameters, text);
	}
	else
	{
		XCTAssertNil(expression, @"Should not be able to parse '%@'", text);
	}
}

- (void)testExpression
{
	[self _textExpression:@"[self goHome:\"no at\"]" expectSuccess:NO parameters:0];
	[self _textExpression:@"[self goHome]" expectSuccess:YES parameters:0];
	[self _textExpression:@"[self goHome:123]" expectSuccess:YES parameters:1];
	[self _textExpression:@"[self goHome:@\"text\" animated:YES]" expectSuccess:YES parameters:2];
	[self _textExpression:@"niente" expectSuccess:NO  parameters:0];
}

@end
