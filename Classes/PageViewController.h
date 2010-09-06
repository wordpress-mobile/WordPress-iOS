//
//  PageViewController.h
//  WordPress
//
//  Created by Chris Boyd on 9/4/10.
//

#import <UIKit/UIKit.h>
#import "TransparentToolbar.h"
#import "WordPressAppDelegate.h"
#import "BlogDataManager.h"
#import "PageManager.h"
#import "DraftManager.h"
#import "Post.h"

@protocol PageViewControllerProtocol

@property (nonatomic, retain) NSString *selectedPostID;
@property (nonatomic, retain) DraftManager *draftManager;
@property (nonatomic, retain) PageManager *pageManager;

- (IBAction)saveAction:(id)sender;
- (IBAction)publishAction:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)dismiss:(id)sender;
- (void)refreshButtons:(BOOL)hasChanges keyboard:(BOOL)isShowingKeyboard;

@end

@interface PageViewController : UIViewController <PageViewControllerProtocol, UITabBarDelegate> {
	IBOutlet UITabBarController *tabController;
	
	NSString *selectedPostID;
	int selectedBDMIndex;
	BOOL isPublished;
	
	BlogDataManager *dm;
	WordPressAppDelegate *appDelegate;
	DraftManager *draftManager;
	PageManager *pageManager;
}

@property (nonatomic, retain) IBOutlet UITabBarController *tabController;
@property (nonatomic, assign) BOOL isPublished;
@property (nonatomic, assign) BlogDataManager *dm;
@property (nonatomic, assign) WordPressAppDelegate *appDelegate;

- (void)setupBackButton;

@end
