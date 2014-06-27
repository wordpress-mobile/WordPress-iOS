//
//  ViewController.m
//  AirDrops
//
//  Created by Stefan Gugarel on 01/11/13.
//  Copyright (c) 2013 . All rights reserved.
//

#import <QuickLook/QuickLook.h>
#import "ViewController.h"
#import "DTFoundation.h"
#import "NSString+DTUtilities.h"
#import "NSString+DTPaths.h"
#import "ZipArchiveCell.h"
#import "DTZipArchive.h"
#import "ZipArchiveManager.h"
#import "ZipArchiveModel.h"
#import "DTZipArchiveNode.h"
#import "ZipNodeViewController.h"

static NSString *cellIdentifier = @"ZipArchiveCellIdentifier";

@interface ViewController () <UIDocumentInteractionControllerDelegate>

@end

@implementation ViewController
{
    UIDocumentInteractionController *_documentInteractionController;

    NSURL *_selectedFileURL;
             
    ZipArchiveManager *_zipArchiveManager;
}

- (void)_prepIcons
{
    for (ZipArchiveModel *zipArchiveModel in _zipArchiveManager.archives)
	{
		[self _setupDocumentControllerWithURL:zipArchiveModel.URL];
	}
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Do any additional setup after loading the view, typically from a nib.
	NSString *documentsPath = [NSString documentsPath];
	NSURL *documentsURL = [NSURL fileURLWithPath:documentsPath];
	_zipArchiveManager = [[ZipArchiveManager alloc] initWithURL:documentsURL];
	
	// monitor for changes to the list of archives, e.g. iTunes file sharing
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(archivesDidChange:) name:ZipArchiveManagerDidReloadArchivesNotification object:_zipArchiveManager];
	
	[self _prepIcons];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_setupDocumentControllerWithURL:(NSURL *)url
{
    if (_documentInteractionController == nil)
    {
        _documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:url];
        _documentInteractionController.delegate = self;
    }
    else
    {
        _documentInteractionController.URL = url;
    }
}


#pragma mark - UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_zipArchiveManager numberOfArchives];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZipArchiveCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (!cell)
    {
        cell = [[ZipArchiveCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    
    ZipArchiveModel *zipArchive = [_zipArchiveManager archiveAtIndex:indexPath.row];
        
    cell.textLabel.text = zipArchive.fileName;
    
    if (zipArchive.unzipped)
    {
        cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.progressView.hidden = NO;
    }
    else
    {
        cell.editingAccessoryType = UITableViewCellAccessoryNone;
        cell.progressView.hidden = YES;
        cell.progressView.progress = zipArchive.progress;
    }
    
    
    NSInteger iconCount = [_documentInteractionController.icons count];
    if (iconCount > 0)
    {
        cell.imageView.image = [_documentInteractionController.icons objectAtIndex:iconCount - 1];
    }
    
    return cell;
}


#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self performSegueWithIdentifier:@"ShowZipArchiveSegue" sender:indexPath];
}


#pragma mark - StoryBoards

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([[segue identifier] isEqualToString:@"ShowZipArchiveSegue"])
	{
		if ([sender isKindOfClass:[NSIndexPath class]])
		{

			// set application to destination view controller
			NSIndexPath *indexPath = (NSIndexPath *)sender;

			ZipArchiveModel *zipArchiveModel = [_zipArchiveManager archiveAtIndex:indexPath.row];


			DTZipArchive *zipArchive = [DTZipArchive archiveAtPath:zipArchiveModel.path];

			DTZipArchiveNode *rootNode = [[DTZipArchiveNode alloc] init];
			rootNode.name = zipArchiveModel.fileName;
			rootNode.directory = YES;
			[rootNode.children addObjectsFromArray:zipArchive.nodes];

			ZipNodeViewController *zipNodeViewController = (ZipNodeViewController *)[segue destinationViewController];

			zipNodeViewController.node = rootNode;
			zipNodeViewController.zipArchive = zipArchive;

		}
	}
}

#pragma mark - Notifications
- (void)archivesDidChange:(NSNotification *)notification
{
	dispatch_async(dispatch_get_main_queue(), ^{
		
		[self _prepIcons];
		[self.tableView reloadData];
	});
}

@end