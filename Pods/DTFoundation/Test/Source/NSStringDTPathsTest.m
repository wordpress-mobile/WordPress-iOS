//
//  NSStringDTPathsTest.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 30.09.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "NSStringDTPathsTest.h"
#import "NSString+DTPaths.h"

@implementation NSStringDTPathsTest


#pragma mark - Standard Paths

- (void)testCachesPath
{
	NSString *string1 = [NSString cachesPath];
	XCTAssertTrue([string1 length], @"There should be a result");
	
	NSString *string2 = [NSString cachesPath];
	XCTAssertTrue([string2 length], @"There should be a result");
	
	XCTAssertTrue([string1 isEqualToString:string2], @"Caches path should always be same");
}

- (void)testDocumentsPath
{
	NSString *string1 = [NSString documentsPath];
	XCTAssertTrue([string1 length], @"There should be a result");
	
	NSString *string2 = [NSString documentsPath];
	XCTAssertTrue([string2 length], @"There should be a result");
	
	XCTAssertTrue([string1 isEqualToString:string2], @"Documents path should always be same");
}

#pragma mark - Temporary Paths

- (void)testTempPath
{
	NSString *string1 = [NSString temporaryPath];
	XCTAssertTrue([string1 length], @"There should be a result");
	
	NSString *string2 = [NSString temporaryPath];
	XCTAssertTrue([string2 length], @"There should be a result");
	
	XCTAssertTrue([string1 isEqualToString:string2], @"Temp path should always be same");
}

- (void)testTempPathForFile
{
	NSString *string1 = [NSString pathForTemporaryFile];
	XCTAssertTrue([string1 length], @"There should be a result");

	NSString *string2 = [NSString pathForTemporaryFile];
	XCTAssertTrue([string2 length], @"There should be a result");
	
	XCTAssertFalse([string1 isEqualToString:string2], @"Temp path for file should be different");
}


#pragma mark - Test Sequence Numbers

- (void)testIncrementSequenceNumber
{
	NSString *fileName = @"file(9).jpg";
	NSString *incremented = [fileName pathByIncrementingSequenceNumber];
	XCTAssertTrue([incremented isEqualToString:@"file(10).jpg"], @"sequence number should be incremented");
	
	fileName = @"file.jpg";
	incremented = [fileName pathByIncrementingSequenceNumber];
	XCTAssertTrue([incremented isEqualToString:@"file(1).jpg"], @"sequence number should be incremented");
	
	fileName = @"file";
	incremented = [fileName pathByIncrementingSequenceNumber];
	XCTAssertTrue([incremented isEqualToString:@"file(1)"], @"sequence number should be incremented");
}

- (void)testDeleteSequenceNumber
{
	NSString *fileName = @"file(999).jpg";
	NSString *deleted = [fileName pathByDeletingSequenceNumber];
	XCTAssertTrue([deleted isEqualToString:@"file.jpg"], @"sequence number should be removed");
}

@end
