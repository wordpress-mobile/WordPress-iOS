//
//  PageViewController.h
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//

#import <UIKit/UIKit.h>
#import "WPPhotosListProtocol.h"
#import "LocationController.h"

@class EditPageViewController, PostPreviewViewController, WPSelectionTableViewController, WPPhotosListViewController, PagesViewController;
@class WPNavigationLeftButtonView;

@interface PageViewController : UIViewController <UITabBarDelegate, UIActionSheetDelegate, UITabBarControllerDelegate, WPPhotosListProtocol> {
    IBOutlet UITabBarController *tabController;
    IBOutlet UIView *photoEditingStatusView;

    UIBarButtonItem *saveButton;

    EditPageViewController *pageDetailViewController;
    WPPhotosListViewController *photosListController;
    PagesViewController *pagesListController;
    WPNavigationLeftButtonView *leftView;

    BOOL hasChanges;
    int mode;   //0 new, 1 edit, 2 autorecovery, 3 refresh
}

@property (nonatomic, retain) WPNavigationLeftButtonView *leftView;
@property (nonatomic, retain) EditPageViewController *pageDetailViewController;
@property (nonatomic, retain) WPPhotosListViewController *photosListController;
@property (nonatomic, assign) PagesViewController *pagesListController;

@property (nonatomic, readonly) UIBarButtonItem *saveButton;

@property (nonatomic) BOOL hasChanges;
@property (nonatomic) int mode;

@property (readonly) UITabBarController *tabController;

- (void)updatePhotosBadge;
- (IBAction)savePageAction:(id)sender;
//- (void)addAsyncPostOperation:(SEL)anOperation withArg:(id)anArg;

@end
