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
@class FlippingViewController;

@interface PageViewController : UIViewController <UITabBarDelegate, UIActionSheetDelegate, UITabBarControllerDelegate, WPPhotosListProtocol> {
    IBOutlet UITabBarController *tabController;
    IBOutlet UIView *photoEditingStatusView;

    UIBarButtonItem *saveButton;

    EditPageViewController *pageDetailViewController;
    EditPageViewController *pageDetailStaticViewController;
    WPPhotosListViewController *photosListController;
    PagesViewController *pagesListController;
    WPNavigationLeftButtonView *leftView;

    BOOL hasChanges;
    int mode;   //0 new, 1 edit, 2 autorecovery, 3 refresh
	
	// iPad additions
	IBOutlet UIToolbar *toolbar;
	IBOutlet UIView *contentView;
	UIPopoverController *popoverController;
	UIPopoverController *photoPickerPopover;
	
	IBOutlet UIToolbar *editToolbar;
	IBOutlet UIBarButtonItem *cancelEditButton;
	FlippingViewController *editModalViewController;
}

@property (nonatomic, retain) WPNavigationLeftButtonView *leftView;
@property (nonatomic, retain) EditPageViewController *pageDetailViewController;
@property (nonatomic, retain) EditPageViewController *pageDetailStaticViewController;
@property (nonatomic, retain) WPPhotosListViewController *photosListController;
@property (nonatomic, assign) PagesViewController *pagesListController;

@property (nonatomic, readonly) UIBarButtonItem *saveButton;

@property (nonatomic) BOOL hasChanges;
@property (nonatomic) int mode;

@property (readonly) UITabBarController *tabController;

@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIView *contentView;

@property (nonatomic, retain) IBOutlet UIToolbar *editToolbar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *cancelEditButton;
@property (nonatomic, retain) FlippingViewController *editModalViewController;

- (UINavigationItem *)navigationItemForEditPost;
@property (nonatomic, assign) UIBarButtonItem *leftBarButtonItemForEditPost;
@property (nonatomic, assign) UIBarButtonItem *rightBarButtonItemForEditPost;

- (void)updatePhotosBadge;
- (IBAction)savePageAction:(id)sender;
- (IBAction)cancelView:(id)sender;
//- (void)addAsyncPostOperation:(SEL)anOperation withArg:(id)anArg;

- (IBAction)editAction:(id)sender;
- (IBAction)picturesAction:(id)sender;

- (void)dismissEditView;

@end
