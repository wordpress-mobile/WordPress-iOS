//
//  DTHTMLParserTest.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 8/9/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTHTMLParserTest.h"
#import "DTHTMLParser.h"

@interface DTHTMLParserTest ()<DTHTMLParserDelegate>

@end

@implementation DTHTMLParserTest

- (void)testNilData
{
	// try to create a parser with nil data
	DTHTMLParser *parser = [[DTHTMLParser alloc] initWithData:nil encoding:NSUTF8StringEncoding];
	
	// make sure that this is nil
	STAssertNil(parser, @"Parser Object should be nil");
}


- (void)testPlainFile
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForResource:@"html_doctype" ofType:@"html"];
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];

    DTHTMLParser *parser = [[DTHTMLParser alloc] initWithData:data encoding:NSUTF8StringEncoding];
	parser.delegate = self;
	
    STAssertTrue([parser parse], @"Cannnot parse");
	STAssertNil(parser.parserError, @"There should be no error");
}

- (void)testProcessingInstruction
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForResource:@"processing_instruction" ofType:@"html"];
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
	DTHTMLParser *parser = [[DTHTMLParser alloc] initWithData:data encoding:NSUTF8StringEncoding];
	parser.delegate = self;
    [parser parse];
	
    STAssertTrue([parser parse], @"Cannnot parse");
	STAssertNil(parser.parserError, @"There should be no error");
}

#pragma mark DTHTMLParserDelegate

- (void)parser:(DTHTMLParser *)parser foundProcessingInstructionWithTarget:(NSString *)target data:(NSString *)data
{
	DTLogDebug(@"target: %@ data: %@", target, data);
}

@end
