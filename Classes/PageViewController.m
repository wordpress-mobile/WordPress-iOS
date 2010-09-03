//
//  PageViewController.m
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//

#import "PageViewController.h"

#import "BlogDataManager.h"
#import "EditPageViewController.h"
#import "PagesViewController.h"
#import "PostsViewController.h"
#import "Reachability.h"
#import "WordPressAppDelegate.h"
#import "WPNavigationLeftButtonView.h"

#import "FlippingViewController.h"
#import "RotatingNavigationController.h"
#import "CPopoverManager.h"

#define TAG_OFFSET 1020

@interface PageViewController (Private)

- (void)_saveAsDrft;
- (void)_savePost:(id)aPost inBlog:(id)aBlog;
- (void)_dismiss;
- (void)_cancel;

@end

@implementation PageViewController

@synthesize pageDetailViewController, pagesListController, hasChanges, tabController, saveButton;
@synthesize leftView, editMode;
@synthesize pageDetailStaticViewController;
@synthesize toolbar;
@synthesize contentView;
@synthesize editToolbar;
@synthesize cancelEditButton;
@synthesize editModalViewController;

@dynamic leftBarButtonItemForEditPost;
@dynamic rightBarButtonItemForEditPost;

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    if ([viewController.title isEqualToString:@"Photos"]) {
//        if ((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
//            [photosListController.view addSubview:photoEditingStatusView];
//        } else if ((self.interfaceOrientation == UIInterfaceOrientationPortrait) || (self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)) {
//            [photoEditingStatusView removeFromSuperview];
//        }

        self.navigationItem.title = @"Media";
    } else {
//        [photoEditingStatusView removeFromSuperview];
        [pageDetailViewController refreshUIForCurrentPage];
        self.navigationItem.title = @"Write";
    }

    self.title = viewController.title;

    if (hasChanges) {
        if ([[leftView title] isEqualToString:@"Pages"]) {
            [leftView setTitle:@"Cancel"];
        }

        self.rightBarButtonItemForEditPost = saveButton;
    }
}

- (void)dealloc {
    [leftView release];
    [pageDetailViewController release];
    [saveButton release];
    [super dealloc];
}

- (void)updatePhotosBadge {
}

#pragma mark - UIActionSheetDelegate

- (void)addProgressIndicator {
    NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
    UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    UIBarButtonItem *activityButtonItem = [[UIBarButtonItem alloc] initWithCustomView:aiv];
    [aiv startAnimating];
    [aiv release];

    self.rightBarButtonItemForEditPost = activityButtonItem;
    [activityButtonItem release];
    [apool release];
}

- (void)removeProgressIndicator {
    NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
    //wait incase the other thread did not complete its work.
    self.rightBarButtonItemForEditPost = nil;

    if (hasChanges) {
        if ([[leftView title] isEqualToString:@"Pages"])
            [leftView setTitle:@"Cancel"];

        self.rightBarButtonItemForEditPost = saveButton;
    }

    [apool release];
}

- (void)_dismiss {
    hasChanges = NO;
    self.rightBarButtonItemForEditPost = nil;
    [[BlogDataManager sharedDataManager] clearAutoSavedContext];
	[self dismissEditView];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag != TAG_OFFSET) {
        [self _dismiss];
    }

    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:NO];
}

- (IBAction)cancelView:(id)sender {
    if (!self.hasChanges) {
		[self dismissEditView];
        return;
    }

    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"You have unsaved changes."
                                  delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Discard"
                                  otherButtonTitles:nil];
    actionSheet.tag = 202;
    actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    [actionSheet showInView:self.view];
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate setAlertRunning:YES];

    [actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch ([actionSheet tag]) {
        case 202:
        {
            if (buttonIndex == 0) {
                self.hasChanges = NO;
                self.rightBarButtonItemForEditPost = nil;
				[self dismissEditView];
            }

            if (buttonIndex == 1) {
                self.hasChanges = YES;

                if ([[leftView title] isEqualToString:@"Pages"])
                    [leftView setTitle:@"Cancel"];
            }

            WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
            [delegate setAlertRunning:NO];

            break;
        }
        default:
            break;
    }
}

- (void)setHasChanges:(BOOL)aFlag {
    hasChanges = aFlag;

    if (hasChanges) {
        if ([[leftView title] isEqualToString:@"Pages"])
            [leftView setTitle:@"Cancel"];

        self.rightBarButtonItemForEditPost = saveButton;
    }

    NSNumber *postEdited = [NSNumber numberWithBool:hasChanges];
    [[[BlogDataManager sharedDataManager] currentPage] setObject:postEdited forKey:@"hasChanges"];
}

#pragma mark - Overridden

- (void)viewDidLoad {
    [super viewDidLoad];

    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:2];

    if (pageDetailViewController == nil) {
		if (DeviceIsPad() == YES) {
			pageDetailViewController = [[EditPageViewController alloc] initWithNibName:@"EditPageViewController-iPad" bundle:nil];
		} else {
			pageDetailViewController = [[EditPageViewController alloc] initWithNibName:@"EditPageViewController" bundle:nil];
		}
        pageDetailViewController.editMode = self.editMode;
    }

    pageDetailViewController.pageDetailsController = self;
    pageDetailViewController.title = @"Write";
    pageDetailViewController.tabBarItem.image = [UIImage imageNamed:@"write.png"];
    [array addObject:pageDetailViewController];

    if (!saveButton) {
        saveButton = [[UIBarButtonItem alloc] init];
        saveButton.title = @"Save";
        saveButton.target = self;
        saveButton.style = UIBarButtonItemStyleDone;
        saveButton.action = @selector(savePageAction:);
    }
	
	if (DeviceIsPad() == YES) {
		// the iPad has two detail views
		pageDetailStaticViewController = [[EditPageViewController alloc] initWithNibName:@"EditPageViewController-iPad" bundle:nil];
		[pageDetailStaticViewController disableInteraction];
		
		if (!editModalViewController) {
			editModalViewController = [[FlippingViewController alloc] init];
			
			RotatingNavigationController *editNav = [[[RotatingNavigationController alloc] initWithRootViewController:pageDetailViewController] autorelease];
			editModalViewController.frontViewController = editNav;
			pageDetailViewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:editToolbar] autorelease];
			pageDetailViewController.navigationItem.leftBarButtonItem = cancelEditButton;
		}
	}
	
	if (tabController) {
		tabController.viewControllers = array;
		self.view = tabController.view;
	}
	else if (toolbar) {
		pageDetailStaticViewController.view.frame = contentView.bounds;
		[contentView addSubview:pageDetailStaticViewController.view];
	}

    //tabController.selectedIndex = 0;

    [array release];
	
	if (DeviceIsPad() == NO)
	{
		if (!leftView) {
			leftView = [WPNavigationLeftButtonView createCopyOfView];
			[leftView setTitle:@"Pages"];
			[leftView setTarget:self withAction:@selector(cancelView:)];
		}

		UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:leftView];
		self.navigationItem.leftBarButtonItem = barButton;
		[barButton release];
	}
}

- (IBAction)savePageAction:(id)sender {
    BlogDataManager *dm = [BlogDataManager sharedDataManager];

    //Check for internet connection
    if (![[dm.currentPage valueForKey:@"page_status"] isEqualToString:@"Local Draft"]) {
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
    }

    if (!hasChanges) {
		[self dismissEditView];
        return;
    }

    [pageDetailViewController endEditingAction:nil];

    NSString *description = [dm.currentPage valueForKey:@"description"];
    NSString *title = [dm.currentPage valueForKey:@"title"];
    NSArray *photos = [dm.currentPage valueForKey:@"Photos"];

    if ((!description ||[description isEqualToString:@""]) &&
        (!title ||[title isEqualToString:@""]) &&
        (!photos || ([photos count] == 0))) {
        NSString *msg = [NSString stringWithFormat:@"Please provide either a title or description or attach photos to the page before saving."];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Page Error"
                              message:msg
                              delegate:self
                              cancelButtonTitle:nil
                              otherButtonTitles:@"OK", nil];
        alert.tag = TAG_OFFSET;
        [alert show];
        WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        [delegate setAlertRunning:YES];

        [alert release];
        [self _cancel];
        return;
    }

    //self.navigationItem.rightBarButtonItem=nil;

    [self performSelectorInBackground:@selector(addProgressIndicator) withObject:nil];

    if ([[dm.currentPage valueForKey:@"page_status"] isEqual:@"Local Draft"]) {
        [self _saveAsDrft];
    } else {
        [dm savePage:dm.currentPage];
        [self performSelectorInBackground:@selector(removeProgressIndicator) withObject:nil];
		[self dismissEditView];
    }

    hasChanges = NO;
	
	[pageDetailStaticViewController refreshUIForCurrentPage];
}

- (void)_saveAsDrft {
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    [dm saveCurrentPageAsDraft];
    hasChanges = NO;
    self.rightBarButtonItemForEditPost = nil;
    [dm removeAutoSavedCurrentPostFile];
    [self _dismiss];
	// kludge
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DraftsUpdated" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	if (DeviceIsPad() == NO) {
		if ((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
			if (pageDetailViewController.isEditing == NO) {
				[pageDetailViewController setTextViewHeight:137];
			} else {
				[pageDetailViewController setTextViewHeight:105];
			}
		}
	}

    //self.navigationItem.title=@"Write";
    [leftView setTarget:self withAction:@selector(cancelView:)];

    if (hasChanges == YES) {
        if ([[leftView title] isEqualToString:@"Pages"]) {
            [leftView setTitle:@"Cancel"];
        }

        self.rightBarButtonItemForEditPost = saveButton;
    } else {
        [leftView setTitle:@"Pages"];
        self.rightBarButtonItemForEditPost = nil;
    }

    [super viewWillAppear:animated];
	
	if (DeviceIsPad() == NO) {
		// For Setting the Button with title Posts.
		UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithCustomView:leftView];
		self.navigationItem.leftBarButtonItem = cancelButton;
		[cancelButton release];

		//Added to solve the title issue .
		[tabController setSelectedViewController:[[tabController viewControllers] objectAtIndex:0]];
		UIViewController *vc = [[tabController viewControllers] objectAtIndex:0];
		WPLog(@"vc.title---%@", vc.title);
		self.title = vc.title;
		//
	}
	else {
		self.title = [[[BlogDataManager sharedDataManager] currentPage] valueForKey:@"title"];
	}

    if(self.editMode == kEditPage) {
        [pageDetailViewController refreshUIForCurrentPage];
		[pageDetailStaticViewController refreshUIForCurrentPage];
	}
	else if(self.editMode == kNewPage) {
        [pageDetailViewController refreshUIForNewPage];
		[pageDetailStaticViewController refreshUIForNewPage];
	}

    [pageDetailViewController viewWillAppear:animated];
	[pageDetailStaticViewController viewWillAppear:animated];
//	[pageDetailViewController refreshUIForCurrentPage];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	
	// should add a refreshUIForCurrentPage to PageViewController mebbe
	if (DeviceIsPad() == YES) {
		if (self.editMode == kNewPage) {
			[self editAction:self];
		}
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	if (DeviceIsPad() == NO) {
		if ((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
			[pageDetailViewController setTextViewHeight:287];
		}
	}

//    [photoEditingStatusView removeFromSuperview];

    if (pageDetailViewController.currentEditingTextField)
        [pageDetailViewController.currentEditingTextField resignFirstResponder];

    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (DeviceIsPad() == YES) {
		return YES;
	}

    //Code to disable landscape when alert is raised.
    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if ([delegate isAlertRunning] == YES)
        return NO;

//    if ([[[[self tabController] selectedViewController] title] isEqualToString:@"Photos"]) {
//        if ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
//            [photosListController.view addSubview:photoEditingStatusView];
//        } else if ((interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)) {
//            [photoEditingStatusView removeFromSuperview];
//        }
//    }
	
	if (DeviceIsPad() == NO) {
		if ((interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)) {
	//        if (pageDetailViewController.isEditing == NO) {
	//            [pageDetailViewController setTextViewHeight:287];
	//        } else {
			   [pageDetailViewController setTextViewHeight:200];
			   return YES;
			}
	//    }

		if ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
			if (pageDetailViewController.isEditing == NO) {
				//[pageDetailViewController setTextViewHeight:137];
			} else {
				[pageDetailViewController setTextViewHeight:105];
				return YES; //trac ticket #148
			}
		}
	}

    //return YES;
	return NO; //trac ticket #148
}

- (void)_cancel {
    hasChanges = YES;

    if ([[leftView title] isEqualToString:@"Pages"])
        [leftView setTitle:@"Cancel"];
}

- (void)useImage:(UIImage *)theImage {

    [self updatePhotosBadge];
}

- (id)photosDataSource {
    return [[[BlogDataManager sharedDataManager] currentPage] valueForKey:@"Photos"];
}

#pragma mark iPad

- (UINavigationItem *)navigationItemForEditPost;
{
	if (DeviceIsPad() == NO) {
		return self.navigationItem;
	} else if (DeviceIsPad() == YES) {
		return pageDetailViewController.navigationItem;
	}
	return nil;
}

- (UIBarButtonItem *)leftBarButtonItemForEditPost;
{
	return [self navigationItemForEditPost].leftBarButtonItem;
}

- (void)setLeftBarButtonItemForEditPost:(UIBarButtonItem *)item;
{
	if (DeviceIsPad() == NO) {
		self.navigationItem.leftBarButtonItem = item;
	} else if (DeviceIsPad() == YES) {
		pageDetailViewController.navigationItem.leftBarButtonItem = item;
	}
}

- (UIBarButtonItem *)rightBarButtonItemForEditPost;
{
	if (DeviceIsPad() == NO) {
		return self.navigationItem.rightBarButtonItem;
	} else if (DeviceIsPad() == YES) {
		return [editToolbar.items lastObject];
	}
	return nil;
}

- (void)setRightBarButtonItemForEditPost:(UIBarButtonItem *)item;
{
	if (DeviceIsPad() == NO) {
		self.navigationItem.rightBarButtonItem = item;
	} else if (DeviceIsPad() == YES) {
		NSArray *currentItems = editToolbar.items;
		if (currentItems.count < 1) return;
		// TODO: uuuugly
		NSMutableArray *newItems = [NSMutableArray arrayWithArray:currentItems];
		
		// if we have an item, replace our last item with it;
		// if it's nil, just gray out the current last item.
		// It's this sort of thing that keeps me from sleeping at night.
		if (item) {
			[newItems replaceObjectAtIndex:(newItems.count - 1) withObject:item];
			[item setEnabled:YES];
		}
		else {
			[[newItems objectAtIndex:(newItems.count - 1)] setEnabled:NO];
		}
		
		[editToolbar setItems:newItems animated:YES];
	}
}

- (IBAction)editAction:(id)sender {
	[pageDetailViewController refreshUIForCurrentPage];
	[editModalViewController setShowingFront:YES animated:NO];
	editModalViewController.modalPresentationStyle = UIModalPresentationPageSheet;
	editModalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	[self.splitViewController presentModalViewController:editModalViewController animated:YES];
}

- (IBAction)picturesAction:(id)sender {
	//UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:photosListController] autorelease];
//	UIPopoverController *popover = [[[NSClassFromString(@"UIPopoverController") alloc] initWithContentViewController:navController] autorelease];
//	[popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
//	[[CPopoverManager instance] setCurrentPopoverController:popover];
}

- (void)dismissEditView;
{
	if (DeviceIsPad() == NO) {
        [self.navigationController popViewControllerAnimated:YES];
	} else {
		[self dismissModalViewControllerAnimated:YES];
		[[BlogDataManager sharedDataManager] loadPageDraftTitlesForCurrentBlog];
		[[BlogDataManager sharedDataManager] loadPageTitlesForCurrentBlog];
	}
}

#pragma mark -
#pragma mark Photo list delegate: iPad

- (void)displayPhotoListImagePicker:(UIImagePickerController *)picker {
//	if (!photoPickerPopover) {
//		photoPickerPopover = [[NSClassFromString(@"UIPopoverController") alloc] initWithContentViewController:picker];
//	}
//	picker.contentSizeForViewInPopover = photosListController.contentSizeForViewInPopover;
//	photoPickerPopover.contentViewController = picker;
//
//	[[CPopoverManager instance] setCurrentPopoverController:NULL];
//	
//	// TODO: this is pretty kludgy
//	UIBarButtonItem *buttonItem = [editToolbar.items objectAtIndex:0];
//	[photoPickerPopover presentPopoverFromBarButtonItem:buttonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
}

- (void)hidePhotoListImagePicker;
{
	[photoPickerPopover dismissPopoverAnimated:NO];
	
	// TODO: this is pretty kludgy
	UIBarButtonItem *buttonItem = [editToolbar.items objectAtIndex:0];
	[popoverController presentPopoverFromBarButtonItem:buttonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
}

@end
