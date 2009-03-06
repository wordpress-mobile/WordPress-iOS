//
//  PageDetailsController.h
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//  Copyright 2008 Prithvi Information Solutions Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WPPhotosListProtocol.h"

@class PageDetailViewController, WPPostDetailPreviewController, WPSelectionTableViewController,  WPPhotosListViewController, PagesListController;
@class WPNavigationLeftButtonView;
@interface PageDetailsController : UIViewController <UITabBarDelegate, UIActionSheetDelegate, UITabBarControllerDelegate,WPPhotosListProtocol> {
	IBOutlet UITabBarController *tabController;
	IBOutlet UIView	*photoEditingStatusView;

	UIBarButtonItem *saveButton;
	
	PageDetailViewController *pageDetailViewController;
	WPPhotosListViewController *photosListController;
	PagesListController *pagesListController;
   	WPNavigationLeftButtonView *leftView;
	
	BOOL hasChanges;
	int mode;	//0 new, 1 edit, 2 autorecovery, 3 refresh
	
	NSTimer *autoSaveTimer;
}

@property (nonatomic, retain)	WPNavigationLeftButtonView *leftView;
@property (nonatomic, retain)	PageDetailViewController *pageDetailViewController;
//@property (nonatomic, retain)	WPPostDetailPreviewController *postPreviewController;
//@property (nonatomic, retain)	WPPostSettingsController *postSettingsController;
@property (nonatomic, retain)	WPPhotosListViewController *photosListController;
@property (nonatomic, assign)	PagesListController *pagesListController;

@property (nonatomic, readonly) UIBarButtonItem * saveButton;


@property (nonatomic)	BOOL hasChanges;
@property (nonatomic)	int mode;

@property (readonly) UITabBarController *tabController;

- (void)updatePhotosBadge;
- (IBAction)savePageAction:(id)sender;
//- (void)addAsyncPostOperation:(SEL)anOperation withArg:(id)anArg;
@end
