//
//  DTHTMLParserTest.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 8/9/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface DTHTMLParserTest : SenTestCase

- (void)testNilData;
- (void)testPlainFile;
- (void)testProcessingInstruction;

@end
