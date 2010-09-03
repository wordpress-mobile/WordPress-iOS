//
//  PagesViewController.m
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//

#import "PagesViewController.h"

#import "BlogDataManager.h"
#import "EditPageViewController.h"
#import "PageViewController.h"
#import "PostTableViewCell.h"
#import "Reachability.h"
#import "WPProgressHUD.h"
#import "IncrementPost.h"

#define LOCAL_DRAFTS_SECTION    0
#define PAGES_SECTION           1
#define NUM_SECTIONS            2

#define TAG_OFFSET 1010

@interface PagesViewController (Private)

- (void)scrollToFirstCell;
- (void)setPageDetailsController;
- (void)refreshHandler;
- (void)syncPages;
- (void)addRefreshButton;
- (void)deletePageAtIndexPath;

@end

@implementation PagesViewController
@synthesize newButtonItem, pageDetailViewController, pageDetailsController, anyMorePages, selectedIndexPath, draftManager;
@synthesize appDelegate;

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.tableView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;

    [self addRefreshButton];
    [self setPageDetailsController];

    newButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                     target:self
                     action:@selector(showAddNewPage)];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if (DeviceIsPad() == YES) {
		if (self.selectedIndexPath) {
			[self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		}
	}
	
	if ([[Reachability sharedReachability] internetConnectionStatus])
	{
		if ([defaults boolForKey:@"refreshPagesRequired"]) {
			[self refreshHandler];
			[defaults setBool:false forKey:@"refreshPagesRequired"];
		}
	}	
	
	[self loadPages];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (DeviceIsPad() == YES)
		return YES;
	
    if ([appDelegate isAlertRunning] == YES)
        return NO;
	
    return YES;
}

#pragma mark -
#pragma mark UITableViewDataSource Methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = TABLE_VIEW_CELL_BACKGROUND_COLOR;

	if (DeviceIsPad() == YES) {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NUM_SECTIONS;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == LOCAL_DRAFTS_SECTION) {
        if ([[BlogDataManager sharedDataManager] numberOfPageDrafts] > 0) {
            return @"Local Drafts";
        } else {
            return NULL;
        }
    } else {
        return @"Pages";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
    if (section == LOCAL_DRAFTS_SECTION)
        return [[BlogDataManager sharedDataManager] numberOfPageDrafts];
	else if ([defaults boolForKey:@"anyMorePages"] == YES)
        return [[BlogDataManager sharedDataManager] countOfPageTitles] +1;
	else
		return [[BlogDataManager sharedDataManager] countOfPageTitles];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
	
    static NSString *CellIdentifier = @"PageCell";
    PostTableViewCell *cell = (PostTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    id page = nil;
    if (cell == nil) {
        cell = [[[PostTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
	
    if (indexPath.section == LOCAL_DRAFTS_SECTION) {
        page = [dm pageDraftTitleAtIndex:indexPath.row];
    } 
	else {
		int count = [[BlogDataManager sharedDataManager] countOfPageTitles];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		//handle the case when it's the last row and we need to return the modified "get more posts" cell
		//note that it's not [[BlogDataManager sharedDataManager] countOfPostTitles] +1 because of the difference in the counting of the datasets
		
		if ([defaults boolForKey:@"anyMorePages"]) {
			if (indexPath.row == count) {
				int totalPages = [[BlogDataManager sharedDataManager] countOfPageTitles];

				if (totalPages == 0) {
					cell .contentView.backgroundColor = TABLE_VIEW_BACKGROUND_COLOR;
					cell.accessoryType = UITableViewCellAccessoryNone;
					return cell;
				}else{
				
					NSString * totalString = [NSString stringWithFormat:@"%d pages total", totalPages];
					[cell changeCellLabelsForUpdate:totalString:@"Load more pages":NO];
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					return cell;
				}
			}
		}
		//if it wasn't the last cell, proceed as normal.
        page = [dm pageTitleAtIndex:indexPath.row];
    }
	
    cell.post = page;
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	BlogDataManager *dm = [BlogDataManager sharedDataManager];

    if (indexPath.section == LOCAL_DRAFTS_SECTION) {
        id currentDraft = [dm pageDraftTitleAtIndex:indexPath.row];

        // Bail out if we're in the middle of saving the draft.
        if ([[currentDraft valueForKey:kAsyncPostFlag] intValue] == 1) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }

        [dm makePageDraftAtIndexCurrent:indexPath.row];
		self.selectedIndexPath = indexPath;
		
    }
	else {
		if (indexPath.row == [[BlogDataManager sharedDataManager] countOfPageTitles]) {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			
			[self performSelectorInBackground:@selector(addSpinnerToCell:) withObject:indexPath];
			[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
			
			IncrementPost *incrementPost = [[IncrementPost alloc] init];
			anyMorePages = [incrementPost loadOlderPages];
			[defaults setBool:anyMorePages forKey:@"anyMorePages"];
			[incrementPost release];
			
			[self performSelectorInBackground:@selector(removeSpinnerFromCell:) withObject:indexPath];
			[self loadPages];
			
			UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:indexPath];
			[cell setNeedsDisplay];
		}
		
        id page = [dm pageTitleAtIndex:indexPath.row];
        if ([[page valueForKey:kAsyncPostFlag] intValue] == 1) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }

        [dm makePageAtIndexCurrent:indexPath.row];
		self.selectedIndexPath = indexPath;

        self.pageDetailsController.hasChanges = NO;
    }

    self.pageDetailsController.editMode = kEditPage;
	
	[self.pageDetailsController viewWillAppear:NO];
	[appDelegate showContentDetailViewController:self.pageDetailsController];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return POST_ROW_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kSectionHeaderHight;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    //return indexPath.section == LOCAL_DRAFTS_SECTION;
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	progressAlert = [[WPProgressHUD alloc] initWithLabel:@"Deleting Page..."];
	[progressAlert show];
	
	[self performSelectorInBackground:@selector(deletePageAtIndexPath:) withObject:indexPath];
}


#pragma mark -
#pragma mark Custom Methods

- (void)scrollToFirstCell {
    NSIndexPath *indexPath = NULL;
    
    if ([self tableView:self.tableView numberOfRowsInSection:LOCAL_DRAFTS_SECTION] > 0) {
        NSUInteger indexes[] = {LOCAL_DRAFTS_SECTION, 0};
        indexPath = [NSIndexPath indexPathWithIndexes:indexes length:2];
    } else if ([self tableView:self.tableView numberOfRowsInSection:PAGES_SECTION] > 0) {
        NSUInteger indexes[] = {PAGES_SECTION, 0};
        indexPath = [NSIndexPath indexPathWithIndexes:indexes length:2];
    }
    
    if (indexPath) {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void)loadPages {
    BlogDataManager *dm = [BlogDataManager sharedDataManager];

    dm.isLocaDraftsCurrent = NO;

    [dm loadPageTitlesForCurrentBlog];
    [dm loadPageDraftTitlesForCurrentBlog];
	
	// avoid calling UIKit on a background thread
	[self performSelectorOnMainThread:@selector(refreshPageList) withObject:nil waitUntilDone:NO];
}

- (void)refreshPageList {
    [self.tableView reloadData];
	
	if (DeviceIsPad() == YES) {
		if (self.selectedIndexPath) {
			// TODO: make this more general. Pages are going to want to do it as well.
			if (self.selectedIndexPath.section >= [self numberOfSectionsInTableView:self.tableView]
				|| self.selectedIndexPath.row >= [self tableView:self.tableView numberOfRowsInSection:self.selectedIndexPath.section])
			{
				return;
			}
			
			[self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
			[self tableView:self.tableView didSelectRowAtIndexPath:self.selectedIndexPath];
		}
	}
}

- (void)addRefreshButton {
    CGRect frame = CGRectMake(0, 0, self.tableView.bounds.size.width, REFRESH_BUTTON_HEIGHT);

    refreshButton = [[RefreshButtonView alloc] initWithFrame:frame];
    [refreshButton addTarget:self action:@selector(refreshHandler) forControlEvents:UIControlEventTouchUpInside];

    self.tableView.tableHeaderView = refreshButton;
}

- (void)refreshHandler {
    [refreshButton startAnimating];
    [self performSelectorInBackground:@selector(syncPages) withObject:nil];
}

- (void)syncPages {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    BlogDataManager *dm = [BlogDataManager sharedDataManager];

    [dm syncPagesForBlog:[dm currentBlog]];
    [self loadPages];

    [refreshButton stopAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [pool release];
}

- (void)showAddNewPage {
    [[BlogDataManager sharedDataManager] makeNewPageCurrent];
    
	self.pageDetailsController.editMode = kNewPage;
	if (DeviceIsPad() == NO) {
		[appDelegate.navigationController pushViewController:self.pageDetailsController animated:YES];
	}
	else if (DeviceIsPad() == YES) {
		[appDelegate showContentDetailViewController:self.pageDetailsController];
		if (self.pageDetailsController.editModalViewController) {
			[self.pageDetailsController editAction:self];
		}
	}
}

- (void) deletePageAtIndexPath:(id)object{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
	NSIndexPath *indexPath = (NSIndexPath*)object;
	
    if (indexPath.section == LOCAL_DRAFTS_SECTION) {
        [dataManager deletePageDraftAtIndex:indexPath.row forBlog:[dataManager currentBlog]];
		[self loadPages];
    }
	else {
		if (indexPath.section == PAGES_SECTION){
			if ([[Reachability sharedReachability] internetConnectionStatus] == NotReachable) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Communication Error."
																message:@"no internet connection."
															   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				alert.tag = TAG_OFFSET;
				[alert show];
				
				WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
				[delegate setAlertRunning:YES];
				[alert release];
				return;
			}
			else {				
				[dataManager makePageAtIndexCurrent:indexPath.row];
				[dataManager deletePage];
				[self syncPages];				
			}
		}
	}
	
	[progressAlert dismissWithClickedButtonIndex:0 animated:YES];
    [progressAlert release];
	
    [pool release];
}

- (void) addSpinnerToCell:(NSIndexPath *)indexPath {
	NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
	
	UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:indexPath];
	[((PostTableViewCell *)cell) runSpinner:YES];
	
	int totalPages = [[BlogDataManager sharedDataManager] countOfPageTitles];
	NSString * totalString = [NSString stringWithFormat:@"%d pages loaded", totalPages];
	[((PostTableViewCell *)cell) changeCellLabelsForUpdate:totalString:@"Loading more pages...":YES];
	
	[apool release];
}

- (void)removeSpinnerFromCell:(NSIndexPath *)indexPath {
	NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
	
	UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:indexPath];
	[((PostTableViewCell *)cell) runSpinner:NO];
	
	[apool release];
}
- (void)setPageDetailsController {
    if (self.pageDetailsController == nil) {
		if (DeviceIsPad() == YES) {
			self.pageDetailsController = [[PageViewController alloc] initWithNibName:@"PageViewController-iPad" bundle:nil];
		} else {
			self.pageDetailsController = [[PageViewController alloc] initWithNibName:@"PageViewController" bundle:nil];
		}
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:NO];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	NSLog(@"Shake detected. Refreshing...");
	if(event.subtype == UIEventSubtypeMotionShake) {
		[self refreshHandler];
	}
}


#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[pageDetailViewController release];
    [pageDetailsController release];
    [newButtonItem release];
    [refreshButton release];
	[selectedIndexPath release];
    [super dealloc];
}

@end
