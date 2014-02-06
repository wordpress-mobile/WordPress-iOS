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
                STAssertTrue([fileName isEqualToString:@"zipFiles"], @"node uncompressed is not as expected");
                break;
            }
            case 1:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/plist"], @"node uncompressed is not as expected");
                break;
            }
            case 2:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/screenshot.png"], @"node uncompressed is not as expected");
                break;
            }
            case 3:
            case 4:
            case 5:
            {
                // ignore __MACOSX/ stuff
                //STAssertTrue([fileName isEqualToString:@"__MACOSX/"], @"node uncompressed is not as expected");
                break;
            }
            case 6:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text"], @"node uncompressed is not as expected");
                break;
            }
            case 7:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text/Andere"], @"node uncompressed is not as expected");
                break;
            }
            case 8:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text/Andere/Franz.txt"], @"node uncompressed is not as expected");
                NSString *originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Franz.txt"];
                [self _compareOriginalFile:originalFilePath withUncompressedFileData:data uncompressedFileName:fileName];
                
                break;
            }
            case 9:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text/Oliver.txt"], @"node uncompressed is not as expected");
                NSString *originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Oliver.txt"];
                [self _compareOriginalFile:originalFilePath withUncompressedFileData:data uncompressedFileName:fileName];
                
                break;
            }
            case 10:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text/Rene"], @"node uncompressed is not as expected");
                NSString *originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Rene"];
                [self _compareOriginalFile:originalFilePath withUncompressedFileData:data uncompressedFileName:fileName];
                
                break;
            }
            case 11:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text/Stefan.txt"], @"node uncompressed is not as expected");
                NSString *originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Stefan.txt"];
                [self _compareOriginalFile:originalFilePath withUncompressedFileData:data uncompressedFileName:fileName];
                
                break;
            }
            case 12:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/text/test"], @"node uncompressed is not as expected");
                break;
            }
            case 13:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/UnitTests-Info.plist"], @"node uncompressed is not as expected");
                break;
            }
            case 14:
            {
                STAssertTrue([fileName isEqualToString:@"zipFiles/UnitTests-Prefix.pch"], @"node uncompressed is not as expected");
                break;
            }

            default:
                STFail(@"Something went wrong");
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
                STAssertTrue([fileName isEqualToString:@"zipFiles"], @"node uncompressed is not as expected");

                // explicit stop -> no other iterations have to follow!
                *stop = YES;

                break;
            }

            default:
                STFail(@"Stopping DTZipArchive failed");
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

        STAssertNil(error, @"Error occured when uncompressing");

        NSFileManager *fileManager = [NSFileManager defaultManager];

        NSString *unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/plist/"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Andere/"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Andere/Franz.txt"];
        NSString *originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Franz.txt"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);
        [self _compareOriginalFile:originalFilePath withUncompressedFile:unzippedFilePath];

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Oliver.txt"];
        originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Oliver.txt"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);
        [self _compareOriginalFile:originalFilePath withUncompressedFile:unzippedFilePath];

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Rene"];
        originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Rene"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected");
        [self _compareOriginalFile:originalFilePath withUncompressedFile:unzippedFilePath];

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/Stefan.txt"];
        originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"Stefan.txt"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);
        [self _compareOriginalFile:originalFilePath withUncompressedFile:unzippedFilePath];

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/text/test/"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/UnitTests-Info.plist"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);

        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/UnitTests-Prefix.pch"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);
        
        // test a file larger than 4K
        unzippedFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"zipFiles/screenshot.png"];
        originalFilePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"screenshot.png"];
        STAssertTrue([fileManager fileExistsAtPath:unzippedFilePath], @"node uncompressed is not as expected: %@", unzippedFilePath);
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
    
    STAssertTrue([originalFileData isEqualToData:uncompressedFileData], @"Uncompressed file: %@ does not match original file: %@", uncompressedFileName, originalFilePath);
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

    STAssertTrue([originalFileData isEqualToData:uncompressedFileData], @"Uncompressed file: %@ does not match original file: %@", uncompressedFilePath, originalFilePath);
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

        STAssertNotNil(error, @"No error with illegal path");
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

		STAssertNil(error, @"Error occured when uncompressing one single file: %@", [error localizedDescription]);

		// TODO compare data
		dispatch_semaphore_signal(semaphore);

	}];

	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
	dispatch_release(semaphore);
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

		STAssertNotNil(error, @"No error raised when uncompressing directory", nil);
		STAssertTrueNoThrow(error.code == 6, @"Wrong error raised. Error should be 6: %@", [error localizedDescription]);

		dispatch_semaphore_signal(semaphore);
	}];

	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
	dispatch_release(semaphore);
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
			STAssertNotNil(error, @"No error raised when uncompressing directory", nil);
			STAssertTrueNoThrow(error.code == 6, @"Wrong error raised. Error should be 6: %@", [error localizedDescription]);
		}
		else
		{
			STAssertNil(error, @"Error raised when uncompressing node", nil);
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
		
		STFail(@"Should not complete uncompressing after cancel was called");
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
		
		STFail(@"Should not complete uncompressing after cancel was called");
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

		STAssertNotNil(error, @"No error raised when uncompressing wrong node", nil);
		STAssertTrueNoThrow(error.code == 7, @"Wrong error raised. Error should be 7: %@", [error localizedDescription]);

		dispatch_semaphore_signal(semaphore);
	}];

	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
	dispatch_release(semaphore);
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

        STAssertTrue([fileName isEqualToString:@"gzip_sample.txt"], @"Wrong file got when uncompressing");

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

        STAssertNil(error, @"Error occured when uncompressing");

        NSFileManager *fileManager = [NSFileManager defaultManager];

        NSString *filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"gzip_sample.txt"];
        STAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);

        NSData *originalFileData = [NSData dataWithContentsOfFile:[testBundle pathForResource:@"gzip_sample.txt" ofType:@"original"]];
        NSData *uncompressedFileData = [NSData dataWithContentsOfFile:filePath];

        STAssertTrue([originalFileData isEqualToData:uncompressedFileData], @"Uncompressed file does not match original file");
		 
		 dispatch_semaphore_signal(semaphore);
    }];
	
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
	dispatch_release(semaphore);
}


- (void)testUncompressingGZipToTargetPathProgress
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
	
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	
	[zipArchive uncompressToPath:[testBundle bundlePath] completion:^(NSError *error) {
		
		STAssertNil(error, @"Error occured when uncompressing");
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		NSString *filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"gzip_sample.txt"];
		STAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);
		
		NSData *originalFileData = [NSData dataWithContentsOfFile:[testBundle pathForResource:@"gzip_sample.txt" ofType:@"original"]];
		NSData *uncompressedFileData = [NSData dataWithContentsOfFile:filePath];
		
		STAssertTrue([originalFileData isEqualToData:uncompressedFileData], @"Uncompressed file does not match original file");
		
		dispatch_semaphore_signal(semaphore);
	}];
	
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
	dispatch_release(semaphore);
	
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
		
		STAssertTrue(currentPercent>=previousPercent, @"progress notification percent should only increase");
		previousPercent = currentPercent;
	}];
	
	[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
	
	STAssertTrue(didGetZeroPercent, @"Should have received zero percent progress");
	STAssertTrue(didReceiveNotification, @"Should have received progress notification");
	STAssertTrue(didGetHundredPercent, @"Should have received hundred percent progress");
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

        STAssertNotNil(error, @"No error with illegal path");
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
		
		STFail(@"Should not complete uncompressing after cancel was called");
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
		
		STFail(@"Should not complete uncompressing after cancel was called");
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
		
		STAssertNil(error, @"Error occured when uncompressing");
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		NSString *filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"gzip_sample.txt"];
		STAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);
		
		NSData *originalFileData = [NSData dataWithContentsOfFile:[testBundle pathForResource:@"gzip_sample.txt" ofType:@"original"]];
		NSData *uncompressedFileData = [NSData dataWithContentsOfFile:filePath];
		
		STAssertTrue([originalFileData isEqualToData:uncompressedFileData], @"Uncompressed file does not match original file");
		
		dispatch_semaphore_signal(semaphore);
	}];
	
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
	dispatch_release(semaphore);
}

- (void)testGZipFilenameWithDashZ
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample" ofType:@"txt-z"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
	
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	
	[zipArchive uncompressToPath:[testBundle bundlePath] completion:^(NSError *error) {
		
		STAssertNil(error, @"Error occured when uncompressing");
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		NSString *filePath = [[testBundle bundlePath] stringByAppendingPathComponent:@"gzip_sample.txt"];
		STAssertTrue([fileManager fileExistsAtPath:filePath], @"node uncompressed is not as expected: %@", filePath);
		
		NSData *originalFileData = [NSData dataWithContentsOfFile:[testBundle pathForResource:@"gzip_sample.txt" ofType:@"original"]];
		NSData *uncompressedFileData = [NSData dataWithContentsOfFile:filePath];
		
		STAssertTrue([originalFileData isEqualToData:uncompressedFileData], @"Uncompressed file does not match original file");
		
		dispatch_semaphore_signal(semaphore);
	}];
	
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
	dispatch_release(semaphore);
}

- (void)testGzipInvalidFilename
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"foo"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
	
	STAssertNil(zipArchive, @"Should not work to instantiate for invalid file name");
}

- (void)testGzipInvalidFile
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample_invalid" ofType:@"gz"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
	
	STAssertNotNil(zipArchive, @"Should be able to instantiate zip archive");
	
	[zipArchive uncompressToPath:[NSString temporaryPath] completion:^(NSError *error) {
		
		STAssertNotNil(error, @"No error with illegal path");
	}];
}

- (void)testGzipInvalidFileEnumeration
{
	DTZipArchiveGZip *zipArchive = [[DTZipArchiveGZip alloc] init];
	
	STAssertNotNil(zipArchive, @"Should be able to instantiate zip archive");
	
	[zipArchive enumerateUncompressedFilesAsDataUsingBlock:^(NSString *fileName, NSData *data, BOOL *stop) {
		STFail(@"Should never get here");
	}];
}


/**
 Tests if calling enumerateUncompressedFilesAsDataUsingBlock
 on object created with [[DTZipArchive alloc] init] has to raise an exception
 */
- (void)testAbstractMethodOfDTZipArchive
{
    DTZipArchive *zipArchive = [[DTZipArchive alloc] init];

    STAssertThrowsSpecificNamed([zipArchive enumerateUncompressedFilesAsDataUsingBlock:^(NSString *fileName, NSData *data, BOOL *stop) {

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
	
	STAssertNil(error, @"Error occured when uncompressing");
	
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
			
		STAssertNil(error, @"Error occured when uncompressing same file twice to same location");
		
		dispatch_semaphore_signal(semaphore);
	}];
	
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
	dispatch_release(semaphore);
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
	STAssertTrue(createFolderWithoutWritePermission, @"Cannot create tmp folder with 555");
	
	// Uncompress to folder with permission denied
	[zipArchive uncompressToPath:tmpDirPath completion:^(NSError *error) {
			
		dispatch_semaphore_signal(semaphore);
		
		STAssertNotNil(error, @"No error raised when uncompressing to target path where permission is denied", nil);
		STAssertTrueNoThrow(error.code == 2, @"Wrong error raised. Error should be 2: %@", [error localizedDescription]);
		
	}];
	
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
	dispatch_release(semaphore);
}

- (void)testSuccessfulUncompressZipArchiveNodeToDataGZip
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
	
	[zipArchive uncompressZipArchiveNode:zipArchive.nodes[0] toDataWithCompletion:^(NSData *data, NSError *error) {
		
		STAssertNil(error, @"Error raised when uncompressing node to data");
		
	}];
}

- (void)testUncompressNilZipArchiveNodeToDataGZip
{
	// get sample.zip file
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSString *sampleZipPath = [testBundle pathForResource:@"gzip_sample.txt" ofType:@"gz"];
	
	DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:sampleZipPath];
	
	[zipArchive uncompressZipArchiveNode:nil toDataWithCompletion:^(NSData *data, NSError *error) {
		
		STAssertNotNil(error, @"No error raised when uncompressing to target path where permission is denied", nil);
		STAssertTrueNoThrow(error.code == 7, @"Wrong error raised. Error should be 7: %@", [error localizedDescription]);
		
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
	
	STAssertNil(data, @"No data should be returned when trying to uncompress invalid node");
	STAssertNotNil(error, @"No error raised when uncompressing to target path where permission is denied", nil);
	STAssertTrueNoThrow(error.code == 7, @"Wrong error raised. Error should be 7: %@", [error localizedDescription]);

}

@end