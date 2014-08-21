//
// ZipNodeViewController.m
// Zippo
//
// Created by Stefan Gugarel on 4/12/13.
// Copyright (c) 2013 Cocoanetics. All rights reserved
//


#import "ZipNodeViewController.h"
#import <QuickLook/QLPreviewController.h>
#import "DTFoundation.h"
#import "NSString+DTUtilities.h"

static NSString *cellIdentifier = @"ZipNodeCellIdentifier";


@interface ZipNodeViewController () <QLPreviewControllerDataSource, QLPreviewControllerDelegate, QLPreviewItem>

@end

@implementation ZipNodeViewController
{
	UIDocumentInteractionController *_documentInteractionController;
	
	/*
	 Here we display all files except files starting with . they are hidden
	 */
	NSArray *_filteredNodeChildrenForQickLook;
	
	/**
	 Here we display all except files starting with __MACOS and files or folders starting with .
	 */
	NSArray *_filteredNodeChildren;
}


#pragma mark - UIView lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = _node.name;
}


#pragma mark - UIDocumentInteractionController

- (void)_setupDocumentInteractionControllerForURL:(NSURL *)fileURL
{
	if (!_documentInteractionController)
	{
		_documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
	}
	
	_documentInteractionController.URL = fileURL;
}


#pragma mark - UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_filteredNodeChildren count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

	if (!cell)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}

	DTZipArchiveNode *node = [_filteredNodeChildren objectAtIndex:indexPath.row];

	cell.textLabel.text = [node.name lastPathComponent];
	
	NSString *filePath = [[NSString cachesPath] stringByAppendingPathComponent:node.name];
	NSURL *fileURL = [NSURL fileURLWithPath:filePath];
	
	[self _setupDocumentInteractionControllerForURL:fileURL];
	
	NSInteger iconCount = [_documentInteractionController.icons count];
	if (iconCount)
	{
		cell.imageView.image = [_documentInteractionController.icons objectAtIndex:iconCount - 1];
	}

	return cell;
}


#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	DTZipArchiveNode *nodeToShow = _filteredNodeChildren[indexPath.row];
	
	if (nodeToShow.isDirectory)
	{
		ZipNodeViewController *zipNodeViewController = [[ZipNodeViewController alloc] init];

		zipNodeViewController.node = _filteredNodeChildren[indexPath.row];
		zipNodeViewController.zipArchive = _zipArchive;

		[self.navigationController pushViewController:zipNodeViewController animated:YES];
	}
	else
	{
		// for case 3 we use the QuickLook APIs directly to preview the document -
		QLPreviewController *previewController = [[QLPreviewController alloc] init];
		previewController.dataSource = self;
		previewController.delegate = self;
		
		// start previewing the document at the current section index
		previewController.currentPreviewItemIndex = indexPath.row;
		[[self navigationController] pushViewController:previewController animated:YES];
	}
}

#pragma mark - QLPreviewController DataSource

/**
 @return The number of items that the preview controller should preview
 */
 - (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)previewController
{
	return [_filteredNodeChildrenForQickLook count];
}

/**
 @return The item that the preview controller should preview
 */
- (id)previewController:(QLPreviewController *)previewController previewItemAtIndex:(NSInteger)idx
{
	
	DTZipArchiveNode *node = _filteredNodeChildrenForQickLook[idx];
	
	// create unique file path for this item
	NSString *filePath = [[NSString cachesPath] stringByAppendingPathComponent:node.name];
	
	// check if file was already created before
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
	
	if (!fileExists)
	{
		NSError *error = nil;
		NSData *data = [_zipArchive uncompressZipArchiveNode:node withError:&error];
		
		if (error)
		{
			DTLogError(@"Error when uncompressing file: %@", [error localizedDescription]);
		}
				
		NSString *directoryPath = [filePath stringByDeletingLastPathComponent];
		[[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&error];
		
		if (error)
		{
			DTLogError(@"Error when creating directory for uncompressed ZIP file: %@", [error localizedDescription]);
		}
		
		NSURL *fileURL = [NSURL fileURLWithPath:filePath];
		[data writeToURL:fileURL atomically:YES];
		
		if (error)
		{
			DTLogError(@"Error when writing uncompressed ZIP file: %@", [error localizedDescription]);
		}
	}
	
	return [NSURL fileURLWithPath:filePath];
}

#pragma mark - Properties

- (void)setNode:(DTZipArchiveNode *)node
{
	if (node != _node)
	{
		_node = node;
		
		NSMutableArray *temporaryNodeChildrenForQuickLook = [NSMutableArray array];
		NSMutableArray *temporaryNodeChildren = [NSMutableArray array];
		
		for (DTZipArchiveNode *childNode in node.children)
		{
			NSString *fileName = [childNode.name lastPathComponent];
			
			// filter files and directories starting with . (hidden) or __MACOS
			if (![fileName hasPrefix:@"."] && ![fileName hasPrefix:@"__MACOSX"])
			{
				[temporaryNodeChildren addObject:childNode];
				
				// add filter to show only files in QuickLook controller
				if (!childNode.isDirectory)
				{
					[temporaryNodeChildrenForQuickLook addObject:childNode];
				}
			}
		}
		
		_filteredNodeChildrenForQickLook = [temporaryNodeChildrenForQuickLook copy];
		_filteredNodeChildren = [temporaryNodeChildren copy];
	}
}

@synthesize previewItemURL = _previewItemURL;

@end