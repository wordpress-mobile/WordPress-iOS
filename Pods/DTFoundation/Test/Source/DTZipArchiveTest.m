//
//  DTZipArchiveTest.m
//  DTFoundation
//
//  Created by Stefan Gugarel on 23.01.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTZipArchiveTest.h"
#import "DTZipArchivePKZip.h"
#import "DTZipArchiveGZip.h"
#import "DTZipArchiveNode.h"


@interface DTZipArchivePKZip (private)

@property (readonly, nonatomic) dispatch_queue_t uncompressingQueue;

@end

@implementation DTZipArchiveTest

- (void)tearDown
{
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *newFilePath = [testBundle pathForResource:@"zipFiles" ofType:nil];
	[[NSFileManager defaultManager] removeItemAtPath:newFilePath error:nil];
}

#pragma mark - PKZip Unit Tests

/**
 Very simple test for DTZipArchive to test if the files that are uncompressed with PKZip have the following order
 */
- (void)testPKZip
{
    // get sample.zip file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *sampleZipPath = [testBundle pathForResource:@"sample" ofType:@"zip"];

    DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

    __block NSUInteger iteration = 0;

    [zipArchive enumerateUncompressedFilesAsDataUsingBlock:^(NSString *fileName, NSData *data, BOOL *stop) {

        switch (iteration)
        {
            case 0:
            {
                XCTAssertTrue([fileName isEqualToString:@"zipFiles"], @"node uncompressed is not as expected");
                break;
            }
            case 1:
            {
                XCTAssertTrue([fileName isEqualToString:@"zipFiles/plist"], @"node uncompressed is not as expected");
                break;
            }
            case 2:
            {
                XCTAssertTrue([fileName isEqualToString:@"zipFiles/screenshot.png"], @"node uncompressed is not as expected");
                break;
            }
            case 3:
            case 4:
            case 5:
            {
                // ignore __MACOSX/ stuff
                //XCTAssertTrue([fileName isEqualToString:@"__MACOSX/"], @"node uncompressed is not as expected");
                break;
            }
            case 6:
            {
                XCTAssertTrue([fileName isEqualToString:@"zipFiles/text"], @"node uncompressed is not as expected");
                break;
            }
            case 7:
            {
                XCTAssertTrue([fileName isEqualToString:@"zipFiles/text/Andere"], @"node uncompressed is not as expected");
                break;
            }
            case 8:
            {
                XCTAssertTrue([fileName isEqualToString:@"zipFiles/text/Andere/Franz.txt"], @"node uncompressed is not as expected");
                NSString *originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Franz.txt"];
                [self _compareOriginalFile:originalFilePath withUncompressedFileData:data uncompressedFileName:fileName];
                
                break;
            }
            case 9:
            {
                XCTAssertTrue([fileName isEqualToString:@"zipFiles/text/Oliver.txt"], @"node uncompressed is not as expected");
                NSString *originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Oliver.txt"];
                [self _compareOriginalFile:originalFilePath withUncompressedFileData:data uncompressedFileName:fileName];
                
                break;
            }
            case 10:
            {
                XCTAssertTrue([fileName isEqualToString:@"zipFiles/text/Rene"], @"node uncompressed is not as expected");
                NSString *originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Rene"];
                [self _compareOriginalFile:originalFilePath withUncompressedFileData:data uncompressedFileName:fileName];
                
                break;
            }
            case 11:
            {
                XCTAssertTrue([fileName isEqualToString:@"zipFiles/text/Stefan.txt"], @"node uncompressed is not as expected");
                NSString *originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Stefan.txt"];
                [self _compareOriginalFile:originalFilePath withUncompressedFileData:data uncompressedFileName:fileName];
                
                break;
            }
            case 12:
            {
                XCTAssertTrue([fileName isEqualToString:@"zipFiles/text/test"], @"node uncompressed is not as expected");
                break;
            }
            case 13:
            {
                XCTAssertTrue([fileName isEqualToString:@"zipFiles/UnitTests-Info.plist"], @"node uncompressed is not as expected");
                break;
            }
            case 14:
            {
                XCTAssertTrue([fileName isEqualToString:@"zipFiles/UnitTests-Prefix.pch"], @"node uncompressed is not as expected");
                break;
            }

            default:
                XCTFail(@"Something went wrong");
        }

        iteration ++;

    }];
}

/**
 Tests if the stop works to abort PKZip uncompression
 */
- (void)testPKZipStop
{
    // get sample.zip file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *sampleZipPath = [testBundle pathForResource:@"sample" ofType:@"zip"];

    DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

    __block NSUInteger iteration = 0;

    [zipArchive enumerateUncompressedFilesAsDataUsingBlock:^(NSString *fileName, NSData *data, BOOL *stop) {

        switch (iteration)
        {
            case 0:
            {
                XCTAssertTrue([fileName isEqualToString:@"zipFiles"], @"node uncompressed is not as expected");

                // explicit stop -> no other iterations have to follow!
                *stop = YES;

                break;
            }

            default:
                XCTFail(@"Stopping DTZipArchive failed");
        }

        iteration ++;

    }];
}


- (void)testUnncompressingPKZipArchiveToTargetPath
{
    // get sample.zip file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *sampleZipPath = [testBundle pathForResource:@"sample" ofType:@"zip"];

    DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

    [zipArchive uncompressToPath:[testBundle bundlePath] completion:^(NSError *error) {

        XCTAssertNil(error, @"Error occured when uncompressing");

        NSFileManager *fileManager = [NSFileManager defaultManager];

        NSString *unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/"];
        XCTAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/plist/"];
        XCTAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/"];
        XCTAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Andere/"];
        XCTAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Andere/Franz.txt"];
        NSString *originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Franz.txt"];
        XCTAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);
        [self _compareOriginalFile:originalFilePath withUncompressedFile:unzippedFilePath];

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Oliver.txt"];
        originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Oliver.txt"];
        XCTAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);
        [self _compareOriginalFile:originalFilePath withUncompressedFile:unzippedFilePath];

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Rene"];
        originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Rene"];
        XCTAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected");
        [self _compareOriginalFile:originalFilePath withUncompressedFile:unzippedFilePath];

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Stefan.txt"];
        originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Stefan.txt"];
        XCTAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);
        [self _compareOriginalFile:originalFilePath withUncompressedFile:unzippedFilePath];

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/test/"];
        XCTAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/UnitTests-Info.plist"];
        XCTAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/UnitTests-Prefix.pch"];
        XCTAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);
        
        // test a file larger than 4K
        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/screenshot.png"];
        originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"screenshot.png"];
        XCTAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);
        [self _compareOriginalFile:originalFilePath withUncompressedFile:unzippedFilePath];

    }];
}


/**
 Compares 1 given original file with data of file
 
 @param originalFilePath path of the original file to compare
 @param uncomressedFileData data of uncompressed file
 @param uncompressedFileName filename of uncompressed file
 */
- (void)_compareOriginalFile:(NSString *)originalFilePath withUncompressedFileData:(NSData *)uncompressedFileData uncompressedFileName:(NSString *)uncompressedFileName
{
    NSData *originalFileData = [NSData dataWithContentsOfFile:originalFilePath];
    
    XCTAssertTrue([originalFileData isEqualToData:uncompressedFileData], @"Uncompressed file: %@ does not match original file: %@", uncompressedFileName, originalFilePath);
}

/**
 Compares 2 given files
 
 @param originalFilePath path of the original file to compare
 @param uncompressedFilePath uncompressed file path for file to compare
 */
- (void)_compareOriginalFile:(NSString *)originalFilePath withUncompressedFile:(NSString *)uncompressedFilePath
{
    NSData *originalFileData = [NSData dataWithContentsOfFile:originalFilePath];
    NSData *uncompressedFileData = [NSData dataWithContentsOfFile:uncompressedFilePath];

    XCTAssertTrue([originalFileData isEqualToData:uncompressedFileData], @"Uncompressed file: %@ does not match original file: %@", uncompressedFilePath, originalFilePath);
}

/**
 Tests uncompressing a PKZip to an invalid target path
 */
- (void)testUncompressingPKZipWithInvalidTargetPath
{
    // get sample.zip file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *sampleZipPath = [testBundle pathForResource:@"sample" ofType:@"zip"];

	// create zip archive
    DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

    [zipArchive uncompressToPath:@"ILLEGAL PATH!!!" completion:^(NSError *error) {

        XCTAssertNotNil(error, @"No error with illegal path");
    }];
}


/**
 Tests uncompressing of one single file from PKZip
 */
- (void)testUncompressingSingleFileFromPKZipWithSuccess
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"sample" ofType:@"zip"];

	// create zip archive
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

	// choose file as node
	DTZipArchiveNode *zipFiles = (DTZipArchiveNode *)zipArchive.nodes[0];
	DTZipArchiveNode *text = (DTZipArchiveNode *)zipFiles.children[2];
	DTZipArchiveNode *andere = (DTZipArchiveNode *)text.children[0];
	DTZipArchiveNode *franzTxt = (DTZipArchiveNode *)andere.children[0];
	

	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[zipArchive uncompressZipArchiveNode:franzTxt toDataWithCompletion:^(NSData *data, NSError *error) {

		XCTAssertNil(error, @"Error occured when uncompressing one single file: %@", [error localizedDescription]);

		// TODO compare data
		dispatch_semaphore_signal(semaphore);

	}];

	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
   
#if !OS_OBJECT_USE_OBJC
	dispatch_release(semaphore);
#endif
}

/**
 Do uncompressing single file test with directory -> ILLEGAL -> Error should be raised
 */
- (void)testUncompressingDirectoryFromPKZip
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"sample" ofType:@"zip"];

	// create zip archive
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

	// choose directory node
	DTZipArchiveNode *rootDirectoryNode = zipArchive.nodes[0];

	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[zipArchive uncompressZipArchiveNode:rootDirectoryNode toDataWithCompletion:^(NSData *data, NSError *error) {

		XCTAssertNotNil(error, @"No error raised when uncompressing directory", nil);
		XCTAssertTrue(error.code == 6, @"Wrong error raised. Error should be 6: %@", [error localizedDescription]);

		dispatch_semaphore_signal(semaphore);
	}];

	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
   
#if !OS_OBJECT_USE_OBJC
	dispatch_release(semaphore);
#endif
}


/**
 Do uncompressing single file test with directory -> ILLEGAL -> Error should be raised
 */
- (void)testUncompressingNodesFromPKZip
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"sample" ofType:@"zip"];
	
	// create zip archive
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
	
	// get specific nodes
	DTZipArchiveNode *zipFilesFolderNode = zipArchive.nodes[0];
	DTZipArchiveNode *textFolderNode = zipFilesFolderNode.children[2];
	
	for (DTZipArchiveNode *node in textFolderNode.children)
	{
		NSError *error = nil;
		
		[zipArchive uncompressZipArchiveNode:node withError:&error];
		
		if (node.isDirectory)
		{
			XCTAssertNotNil(error, @"No error raised when uncompressing directory", nil);
			XCTAssertTrue(error.code == 6, @"Wrong error raised. Error should be 6: %@", [error localizedDescription]);
		}
		else
		{
			XCTAssertNil(error, @"Error raised when uncompressing node", nil);
		}
	}
}

- (void)testCancelUncompressingPKZip
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"sample" ofType:@"zip"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
			
	[zipArchive uncompressToPath:[testBundle bundlePath] completion:^(NSError *error) {
		
		XCTFail(@"Should not complete uncompressing after cancel was called");
	}];
	
	[zipArchive cancelAllUncompressing];
	
	[NSThread sleepForTimeInterval:0.2f];
}

- (void)testCancelUncompressingPKZipAfter1ms
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"sample" ofType:@"zip"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
		
	[zipArchive uncompressToPath:[testBundle bundlePath] completion:^(NSError *error) {
		
		XCTFail(@"Should not complete uncompressing after cancel was called");
	}];
	
	[NSThread sleepForTimeInterval:0.0001f];
	
	// cancel uncompression after 1ms -> to cancel in while loop
	[zipArchive cancelAllUncompressing];
	
	[NSThread sleepForTimeInterval:0.5f];
}

/**
 Do uncompressing with illegal manually create node -> Error should be raised
 */
- (void)testUncompressingWrongNodeFromPKZip
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"sample" ofType:@"zip"];

	// create zip archive
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

	// create illegal node manually
	DTZipArchiveNode *wrongNode = [[DTZipArchiveNode alloc] init];
	wrongNode.name = @"FALSCHER NAME!!!";
	wrongNode.directory = NO;


	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

	[zipArchive uncompressZipArchiveNode:wrongNode toDataWithCompletion:^(NSData *data, NSError *error) {

		XCTAssertNotNil(error, @"No error raised when uncompressing wrong node", nil);
		XCTAssertTrue(error.code == 7, @"Wrong error raised. Error should be 7: %@", [error localizedDescription]);

		dispatch_semaphore_signal(semaphore);
	}];

	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

#if !OS_OBJECT_USE_OBJC
	dispatch_release(semaphore);
#endif
}


#pragma mark - GZip Unit tests

/**
 Tests uncompression for GZip
 */
- (void)testGZip
{
    // get sample.zip file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];

    DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

    [zipArchive enumerateUncompressedFilesAsDataUsingBlock:^(NSString *fileName, NSData *data, BOOL *stop) {

        XCTAssertTrue([fileName isEqualToString:@"gzip_sample.txt"], @"Wrong file got when uncompressing");

    }];
}



/**
 Tests uncompression to a specified target path
 */
- (void)testUncompressingGZipToTargetPath
{
    // get sample.zip file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];

    DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	
    [zipArchive uncompressToPath:[testBundle bundlePath] completion:^(NSError *error) {

        XCTAssertNil(error, @"Error occured when uncompressing");

        NSFileManager *fileManager = [NSFileManager defaultManager];

        NSString *filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"gzip_sample.txt"];
        XCTAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);

        NSData *originalFileData = [NSData dataWithContentsOfFile:[testBundle pathForResource:@"gzip_sample.txt" ofType:@"original"]];
        NSData *uncompressedFileData = [NSData dataWithContentsOfFile:filePath];

        XCTAssertTrue([originalFileData isEqualToData:uncompressedFileData], @"Uncompressed file does not match original file");
		 
		 dispatch_semaphore_signal(semaphore);
    }];
	
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
   
#if !OS_OBJECT_USE_OBJC
	dispatch_release(semaphore);
#endif
}


- (void)testUncompressingGZipToTargetPathProgress
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
	
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	
	[zipArchive uncompressToPath:[testBundle bundlePath] completion:^(NSError *error) {
		
		XCTAssertNil(error, @"Error occured when uncompressing");
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		NSString *filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"gzip_sample.txt"];
		XCTAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);
		
		NSData *originalFileData = [NSData dataWithContentsOfFile:[testBundle pathForResource:@"gzip_sample.txt" ofType:@"original"]];
		NSData *uncompressedFileData = [NSData dataWithContentsOfFile:filePath];
		
		XCTAssertTrue([originalFileData isEqualToData:uncompressedFileData], @"Uncompressed file does not match original file");
		
		dispatch_semaphore_signal(semaphore);
	}];
	
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
   
#if !OS_OBJECT_USE_OBJC
	dispatch_release(semaphore);
#endif
	
	__block BOOL didReceiveNotification = NO;
	__block BOOL didGetZeroPercent = NO;
	__block BOOL didGetHundredPercent = NO;
	__block float previousPercent = 0;
	
	
	[[NSNotificationCenter defaultCenter] addObserverForName:DTZipArchiveProgressNotification object:zipArchive queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		didReceiveNotification = YES;
		
		NSDictionary *userInfo = [note userInfo];
		float currentPercent = [userInfo[@"ProgressPercent"] floatValue];
		
		if (currentPercent == 0)
		{
			didGetZeroPercent = YES;
		}
		
		if (currentPercent == 1)
		{
			didGetHundredPercent = YES;
		}
		
		XCTAssertTrue(currentPercent>=previousPercent, @"progress notification percent should only increase");
		previousPercent = currentPercent;
	}];
	
	[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
	
	XCTAssertTrue(didGetZeroPercent, @"Should have received zero percent progress");
	XCTAssertTrue(didReceiveNotification, @"Should have received progress notification");
	XCTAssertTrue(didGetHundredPercent, @"Should have received hundred percent progress");
}

/**
 Tests uncompressing a GZip to an invalid target path
 */
- (void)testUncompressingGzipWithInvalidTargetPath
{
    // get sample.zip file
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];

    DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];

    [zipArchive uncompressToPath:@"ILLEGAL PATH!!!" completion:^(NSError *error) {

        XCTAssertNotNil(error, @"No error with illegal path");
    }];
}

- (void)testCancelUncompressingGZip
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];
	
	DTZipArchivePKZip *zipArchive = (DTZipArchivePKZip *)[DTZipArchive archiveAtPath:sampleZipPath];
	
	// suspend the queue to let us set the cancel
	dispatch_suspend(zipArchive.uncompressingQueue);
	
	[zipArchive uncompressToPath:[testBundle bundlePath] completion:^(NSError *error) {
		
		XCTFail(@"Should not complete uncompressing after cancel was called");
	}];
	
	// resume
	[zipArchive cancelAllUncompressing];
	
	dispatch_resume(zipArchive.uncompressingQueue);
	
	[NSThread sleepForTimeInterval:0.2];
}

- (void)testCancelUncompressingGZipAfter1ms
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
	
	[zipArchive uncompressToPath:[testBundle bundlePath] completion:^(NSError *error) {
		
		XCTFail(@"Should not complete uncompressing after cancel was called");
	}];
	
	[NSThread sleepForTimeInterval:0.0001];
	
	[zipArchive cancelAllUncompressing];
	
	[NSThread sleepForTimeInterval:0.2];
}

- (void)testGZipFilenameWithDashGz
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample" ofType:@"txt-gz"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
	
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	
	[zipArchive uncompressToPath:[testBundle bundlePath] completion:^(NSError *error) {
		
		XCTAssertNil(error, @"Error occured when uncompressing");
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		NSString *filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"gzip_sample.txt"];
		XCTAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);
		
		NSData *originalFileData = [NSData dataWithContentsOfFile:[testBundle pathForResource:@"gzip_sample.txt" ofType:@"original"]];
		NSData *uncompressedFileData = [NSData dataWithContentsOfFile:filePath];
		
		XCTAssertTrue([originalFileData isEqualToData:uncompressedFileData], @"Uncompressed file does not match original file");
		
		dispatch_semaphore_signal(semaphore);
	}];
	
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
   
#if !OS_OBJECT_USE_OBJC
	dispatch_release(semaphore);
#endif
}

- (void)testGZipFilenameWithDashZ
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample" ofType:@"txt-z"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
	
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	
	[zipArchive uncompressToPath:[testBundle bundlePath] completion:^(NSError *error) {
		
		XCTAssertNil(error, @"Error occured when uncompressing");
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		NSString *filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"gzip_sample.txt"];
		XCTAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);
		
		NSData *originalFileData = [NSData dataWithContentsOfFile:[testBundle pathForResource:@"gzip_sample.txt" ofType:@"original"]];
		NSData *uncompressedFileData = [NSData dataWithContentsOfFile:filePath];
		
		XCTAssertTrue([originalFileData isEqualToData:uncompressedFileData], @"Uncompressed file does not match original file");
		
		dispatch_semaphore_signal(semaphore);
	}];
	
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

#if !OS_OBJECT_USE_OBJC
	dispatch_release(semaphore);
#endif
}

- (void)testGzipInvalidFilename
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"foo"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
	
	XCTAssertNil(zipArchive, @"Should not work to instantiate for invalid file name");
}

- (void)testGzipInvalidFile
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample_invalid" ofType:@"gz"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
	
	XCTAssertNotNil(zipArchive, @"Should be able to instantiate zip archive");
	
	[zipArchive uncompressToPath:[NSString temporaryPath] completion:^(NSError *error) {
		
		XCTAssertNotNil(error, @"No error with illegal path");
	}];
}

- (void)testGzipInvalidFileEnumeration
{
	DTZipArchiveGZip *zipArchive = [[DTZipArchiveGZip alloc] init];
	
	XCTAssertNotNil(zipArchive, @"Should be able to instantiate zip archive");
	
	[zipArchive enumerateUncompressedFilesAsDataUsingBlock:^(NSString *fileName, NSData *data, BOOL *stop) {
		XCTFail(@"Should never get here");
	}];
}


/**
 Tests if calling enumerateUncompressedFilesAsDataUsingBlock
 on object created with [[DTZipArchive alloc] init] has to raise an exception
 */
- (void)testAbstractMethodOfDTZipArchive
{
    DTZipArchive *zipArchive = [[DTZipArchive alloc] init];

    XCTAssertThrowsSpecificNamed([zipArchive enumerateUncompressedFilesAsDataUsingBlock:^(NSString *fileName, NSData *data, BOOL *stop) {

    }] , NSException, @"DTAbstractClassException", @"Calling this method on [[DTZipArchive alloc] init] object should cause exception");

}

- (void)testUncompressZipArchiveNodeGZip
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
	
	//
	DTZipArchiveNode *rootNode = zipArchive.nodes[0];
	
	NSError *error = nil;
	[zipArchive uncompressZipArchiveNode:rootNode withError:&error];
	
	XCTAssertNil(error, @"Error occured when uncompressing");
	
}

- (void)testUncompressZipArchiveNodeGZipTwice
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
	
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	
	[zipArchive uncompressToPath:[NSString temporaryPath] completion:^(NSError *error) {
		
		dispatch_semaphore_signal(semaphore);
		
	}];
	
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
	semaphore = dispatch_semaphore_create(0);
	
	[zipArchive uncompressToPath:[NSString temporaryPath] completion:^(NSError *error) {
			
		XCTAssertNil(error, @"Error occured when uncompressing same file twice to same location");
		
		dispatch_semaphore_signal(semaphore);
	}];
	
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
   
#if !OS_OBJECT_USE_OBJC
	dispatch_release(semaphore);
#endif
}

- (void)testUncompressGZipToTargetPathWithMissingPermissions
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
	
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *tmpDirPath = [NSString pathForTemporaryFile];
	NSURL *pathURL = [NSURL fileURLWithPath:tmpDirPath];
	
	NSDictionary *attributes = @{NSFilePosixPermissions: @(555)};
	
	BOOL createFolderWithoutWritePermission = [fileManager createDirectoryAtURL:pathURL withIntermediateDirectories:NO attributes:attributes error:NULL];
	XCTAssertTrue(createFolderWithoutWritePermission, @"Cannot create tmp folder with 555");
	
	// Uncompress to folder with permission denied
	[zipArchive uncompressToPath:tmpDirPath completion:^(NSError *error) {
			
		dispatch_semaphore_signal(semaphore);
		
		XCTAssertNotNil(error, @"No error raised when uncompressing to target path where permission is denied", nil);
		XCTAssertTrue(error.code == 2, @"Wrong error raised. Error should be 2: %@", [error localizedDescription]);
		
	}];
	
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
   
#if !OS_OBJECT_USE_OBJC
	dispatch_release(semaphore);
#endif
}

- (void)testSuccessfulUncompressZipArchiveNodeToDataGZip
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
	
	[zipArchive uncompressZipArchiveNode:zipArchive.nodes[0] toDataWithCompletion:^(NSData *data, NSError *error) {
		
		XCTAssertNil(error, @"Error raised when uncompressing node to data");
		
	}];
}

- (void)testUncompressNilZipArchiveNodeToDataGZip
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
	
	[zipArchive uncompressZipArchiveNode:nil toDataWithCompletion:^(NSData *data, NSError *error) {
		
		XCTAssertNotNil(error, @"No error raised when uncompressing to target path where permission is denied", nil);
		XCTAssertTrue(error.code == 7, @"Wrong error raised. Error should be 7: %@", [error localizedDescription]);
		
	}];
}

- (void)testUncompressInvalidZipArchiveNodeToDataGZip
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
	
	DTZipArchiveNode *invalidNode = [[DTZipArchiveNode alloc] init];
	
	NSError *error;
	
	NSData *data = [zipArchive uncompressZipArchiveNode:invalidNode withError:&error];
	
	XCTAssertNil(data, @"No data should be returned when trying to uncompress invalid node");
	XCTAssertNotNil(error, @"No error raised when uncompressing to target path where permission is denied", nil);
	XCTAssertTrue(error.code == 7, @"Wrong error raised. Error should be 7: %@", [error localizedDescription]);

}

@end