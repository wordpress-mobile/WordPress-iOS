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
#import "WPPhotosListViewController.h"

#define TAG_OFFSET 1020

@interface PageViewController (Private)

- (void)_saveAsDrft;
- (void)_savePost:(id)aPost inBlog:(id)aBlog;
- (void)_dismiss;
- (void)_cancel;

@end

@implementation PageViewController

@synthesize pageDetailViewController, pagesListController, hasChanges, mode, tabController, photosListController, saveButton;
@synthesize leftView;

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    if ([viewController.title isEqualToString:@"Photos"]) {
//        if ((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
//            [photosListController.view addSubview:photoEditingStatusView];
//        } else if ((self.interfaceOrientation == UIInterfaceOrientationPortrait) || (self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)) {
//            [photoEditingStatusView removeFromSuperview];
//        }

        [photosListController refreshData];
        self.navigationItem.title = @"Photos";
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

        self.navigationItem.rightBarButtonItem = saveButton;
    }
}

- (void)dealloc {
    [leftView release];
    [pageDetailViewController release];
    [photosListController release];
    [saveButton release];
    [super dealloc];
}

- (void)updatePhotosBadge {
    int photoCount = [[[BlogDataManager sharedDataManager].currentPage valueForKey:@"Photos"] count];

    if (photoCount)
        photosListController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", photoCount];else
        photosListController.tabBarItem.badgeValue = nil;
}

#pragma mark - UIActionSheetDelegate

- (void)addProgressIndicator {
    NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
    UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    UIBarButtonItem *activityButtonItem = [[UIBarButtonItem alloc] initWithCustomView:aiv];
    [aiv startAnimating];
    [aiv release];

    self.navigationItem.rightBarButtonItem = activityButtonItem;
    [activityButtonItem release];
    [apool release];
}

- (void)removeProgressIndicator {
    NSAutoreleasePool *apool = [[NSAutoreleasePool alloc] init];
    //wait incase the other thread did not complete its work.
    self.navigationItem.rightBarButtonItem = nil;

    if (hasChanges) {
        if ([[leftView title] isEqualToString:@"Pages"])
            [leftView setTitle:@"Cancel"];

        self.navigationItem.rightBarButtonItem = saveButton;
    }

    [apool release];
}

- (void)_dismiss {
    hasChanges = NO;
    self.navigationItem.rightBarButtonItem = nil;
    [[BlogDataManager sharedDataManager] clearAutoSavedContext];
    [self.navigationController popViewControllerAnimated:YES];
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
        [self.navigationController popViewControllerAnimated:YES];
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
                self.navigationItem.rightBarButtonItem = nil;
                [self.navigationController popViewControllerAnimated:YES];
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

        self.navigationItem.rightBarButtonItem = saveButton;
    }

    NSNumber *postEdited = [NSNumber numberWithBool:hasChanges];
    [[[BlogDataManager sharedDataManager] currentPage] setObject:postEdited forKey:@"hasChanges"];
}

#pragma mark - Overridden

- (void)viewDidLoad {
    [super viewDidLoad];

    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:2];

    if (pageDetailViewController == nil) {
        pageDetailViewController = [[EditPageViewController alloc] initWithNibName:@"EditPageViewController" bundle:nil];
        pageDetailViewController.mode = self.mode;
    }

    pageDetailViewController.pageDetailsController = self;
    pageDetailViewController.title = @"Write";
    pageDetailViewController.tabBarItem.image = [UIImage imageNamed:@"write.png"];
    [array addObject:pageDetailViewController];

    if (photosListController == nil) {
        photosListController = [[WPPhotosListViewController alloc] initWithNibName:@"WPPhotosListViewController" bundle:nil];
    }

    pageDetailViewController.photosListController = photosListController;
    photosListController.title = @"Photos";
    photosListController.tabBarItem.image = [UIImage imageNamed:@"photos.png"];
//	photosListController.pageDetailViewController = self.pageDetailViewController;
//	photosListController.pageDetailsController = self;
    photosListController.delegate = self;

    if (!saveButton) {
        saveButton = [[UIBarButtonItem alloc] init];
        saveButton.title = @"Save";
        saveButton.target = self;
        saveButton.style = UIBarButtonItemStyleDone;
        saveButton.action = @selector(savePageAction :);
    }

    [array addObject:photosListController];

    tabController.viewControllers = array;
    self.view = tabController.view;

    //tabController.selectedIndex = 0;

    [array release];

    if (!leftView) {
        leftView = [WPNavigationLeftButtonView createCopyOfView];
    }

    [leftView setTitle:@"Pages"];
    [leftView setTarget:self withAction:@selector(cancelView:)];

    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:leftView];
    self.navigationItem.leftBarButtonItem = barButton;
    [barButton release];
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
        [self.navigationController popViewControllerAnimated:YES];
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
        [self.navigationController popViewControllerAnimated:YES];
    }

    hasChanges = NO;
}

- (void)_saveAsDrft {
    BlogDataManager *dm = [BlogDataManager sharedDataManager];
    [dm saveCurrentPageAsDraft];
    hasChanges = NO;
    self.navigationItem.rightBarButtonItem = nil;
    [dm removeAutoSavedCurrentPostFile];
    [self _dismiss];
}

- (void)viewWillAppear:(BOOL)animated {
    if ((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        if (pageDetailViewController.isEditing == NO) {
            [pageDetailViewController setTextViewHeight:137];
        } else {
            [pageDetailViewController setTextViewHeight:105];
        }
    }

    //self.navigationItem.title=@"Write";
    [leftView setTarget:self withAction:@selector(cancelView:)];

    if (hasChanges == YES) {
        if ([[leftView title] isEqualToString:@"Pages"]) {
            [leftView setTitle:@"Cancel"];
        }

        self.navigationItem.rightBarButtonItem = saveButton;
    } else {
        [leftView setTitle:@"Pages"];
        self.navigationItem.rightBarButtonItem = nil;
    }

    // For Setting the Button with title Posts.
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithCustomView:leftView];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];

    [super viewWillAppear:animated];

    //Added to solve the title issue .
    [tabController setSelectedViewController:[[tabController viewControllers] objectAtIndex:0]];
    UIViewController *vc = [[tabController viewControllers] objectAtIndex:0];
    WPLog(@"vc.title---%@", vc.title);
    self.title = vc.title;
    //

    if (mode == editPage)
        [pageDetailViewController refreshUIForCurrentPage];else if (mode == newPage)
        [pageDetailViewController refreshUIForNewPage];

    [pageDetailViewController viewWillAppear:animated];
//	[pageDetailViewController refreshUIForCurrentPage];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    if ((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        [pageDetailViewController setTextViewHeight:287];
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
    //Code to disable landscape when alert is raised.
//    WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
//
//    if ([delegate isAlertRunning] == YES)
//        return NO;

//    if ([[[[self tabController] selectedViewController] title] isEqualToString:@"Photos"]) {
//        if ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
//            [photosListController.view addSubview:photoEditingStatusView];
//        } else if ((interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)) {
//            [photoEditingStatusView removeFromSuperview];
//        }
//    }

//    if ((interfaceOrientation == UIInterfaceOrientationPortrait) || (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)) {
//        if (pageDetailViewController.isEditing == NO) {
//            [pageDetailViewController setTextViewHeight:287];
//        } else {
           [pageDetailViewController setTextViewHeight:200];
//		   return YES;
//        }
//    }

//    if ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
//        if (pageDetailViewController.isEditing == NO) {
//            //[pageDetailViewController setTextViewHeight:137];
//        } else {
//            [pageDetailViewController setTextViewHeight:105];
//			return YES; //trac ticket #148
//        }
//    }

    //return YES;
	return NO; //trac ticket #148
}

- (void)_cancel {
    hasChanges = YES;

    if ([[leftView title] isEqualToString:@"Pages"])
        [leftView setTitle:@"Cancel"];
}

- (void)useImage:(UIImage *)theImage {
    BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
    self.hasChanges = YES;

    id currentPage = dataManager.currentPage;

    if (![currentPage valueForKey:@"Photos"])
        [currentPage setValue:[NSMutableArray array] forKey:@"Photos"];

    UIImage *image = [photosListController scaleAndRotateImage:theImage scaleFlag:YES];
    [[currentPage valueForKey:@"Photos"] addObject:[dataManager saveImage:image]];

    [self updatePhotosBadge];
}

- (id)photosDataSource {
    return [[[BlogDataManager sharedDataManager] currentPage] valueForKey:@"Photos"];
}

@end
