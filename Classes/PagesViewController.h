//
//  PagesViewController.h
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//

#import <UIKit/UIKit.h>

@class EditPageViewController,PagePhotosViewController;

@interface PagesViewController : UIViewController {
	IBOutlet UITableView *pagesTableView;
	EditPageViewController *pageDetailViewController;
	PagePhotosViewController *pageDetailsController;
	
	BOOL connectionStatus;
	
	IBOutlet UIToolbar *toolbar;
	UIBarButtonItem *refreshButton;
}

@property (nonatomic, retain) EditPageViewController *pageDetailViewController;
@property (nonatomic, retain) PagePhotosViewController *pageDetailsController;

@end
