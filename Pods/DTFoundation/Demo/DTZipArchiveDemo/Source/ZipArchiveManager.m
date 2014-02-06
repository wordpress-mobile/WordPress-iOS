//
//  ZipArchiveManager.m
//  Zippo
//
//  Created by Stefan Gugarel on 3/15/13.
//  Copyright (c) 2013 Drobnik KG. All rights reserved.
//

#import "ZipArchiveManager.h"
#import "ZipArchiveModel.h"
#import "DTZipArchive.h"
#import "NSString+DTPaths.h"
#import "DTFolderMonitor.h"


NSString * const ZipArchiveManagerDidReloadArchivesNotification = @"ZipArchiveManagerDidReloadArchivesNotification";

@implementation ZipArchiveManager
{
    NSMutableDictionary *_zipArchivesDictionary;
	
	DTFolderMonitor *_documentsFolderMonitor;
}


- (id)initWithURL:(NSURL *)URL
{
    self = [super init];
    if (self)
    {
        _URL = URL;
        
        [self _setup];
		
		// install a folder monitor
		__weak ZipArchiveManager *weakself = self;
		_documentsFolderMonitor = [DTFolderMonitor folderMonitorForURL:_URL block:^{
			
			[weakself _setup];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:ZipArchiveManagerDidReloadArchivesNotification object:weakself];
		}];
		
		[_documentsFolderMonitor startMonitoring];
    }
    return self;
}

- (void)_setup
{
    NSMutableArray *temporaryZipArchives = [NSMutableArray array];
    
    _zipArchivesDictionary = [NSMutableDictionary dictionary];
    
    NSError *error = nil;
    NSURL *documentsURL = [NSURL fileURLWithPath:[NSString documentsPath]];
    NSArray *documentsDirectoryContents =[[NSFileManager defaultManager] contentsOfDirectoryAtURL:documentsURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    
    for (NSURL* fileURL in documentsDirectoryContents)
    {
        BOOL isDirectory = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:[fileURL absoluteString] isDirectory:&isDirectory];
        
        // proceed to add the document URL to our list (only add .zip files)
        if (!isDirectory && ([[fileURL lastPathComponent] hasSuffix:@".zip"] || [[fileURL lastPathComponent] hasSuffix:@".gz"]))
        {
            ZipArchiveModel *zipArchive = [[ZipArchiveModel alloc] initWithURL:fileURL];
            [temporaryZipArchives addObject:zipArchive];
            _zipArchivesDictionary[zipArchive.path] = zipArchive;
        }
    }
    
    _archives = [temporaryZipArchives copy];
}

- (NSUInteger)numberOfArchives
{
    return [_archives count];
}

- (ZipArchiveModel *)archiveAtIndex:(NSUInteger)index
{
    return _archives[index];
}

@end
