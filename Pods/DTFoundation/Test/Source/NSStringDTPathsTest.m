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
	STAssertTrue([string1 length], @"There should be a result");
	
	NSString *string2 = [NSString cachesPath];
	STAssertTrue([string2 length], @"There should be a result");
	
	STAssertTrue([string1 isEqualToString:string2], @"Caches path should always be same");
}

- (void)testDocumentsPath
{
	NSString *string1 = [NSString documentsPath];
	STAssertTrue([string1 length], @"There should be a result");
	
	NSString *string2 = [NSString documentsPath];
	STAssertTrue([string2 length], @"There should be a result");
	
	STAssertTrue([string1 isEqualToString:string2], @"Documents path should always be same");
}

#pragma mark - Temporary Paths

- (void)testTempPath
{
	NSString *string1 = [NSString temporaryPath];
	STAssertTrue([string1 length], @"There should be a result");
	
	NSString *string2 = [NSString temporaryPath];
	STAssertTrue([string2 length], @"There should be a result");
	
	STAssertTrue([string1 isEqualToString:string2], @"Temp path should always be same");
}

- (void)testTempPathForFile
{
	NSString *string1 = [NSString pathForTemporaryFile];
	STAssertTrue([string1 length], @"There should be a result");

	NSString *string2 = [NSString pathForTemporaryFile];
	STAssertTrue([string2 length], @"There should be a result");
	
	STAssertFalse([string1 isEqualToString:string2], @"Temp path for file should be different");
}


#pragma mark - Test Sequence Numbers

- (void)testIncrementSequenceNumber
{
	NSString *fileName = @"file(9).jpg";
	NSString *incremented = [fileName pathByIncrementingSequenceNumber];
	STAssertTrue([incremented isEqualToString:@"file(10).jpg"], @"sequence number should be incremented");
	
	fileName = @"file.jpg";
	incremented = [fileName pathByIncrementingSequenceNumber];
	STAssertTrue([incremented isEqualToString:@"file(1).jpg"], @"sequence number should be incremented");
	
	fileName = @"file";
	incremented = [fileName pathByIncrementingSequenceNumber];
	STAssertTrue([incremented isEqualToString:@"file(1)"], @"sequence number should be incremented");
}

- (void)testDeleteSequenceNumber
{
	NSString *fileName = @"file(999).jpg";
	NSString *deleted = [fileName pathByDeletingSequenceNumber];
	STAssertTrue([deleted isEqualToString:@"file.jpg"], @"sequence number should be removed");
}

@end
