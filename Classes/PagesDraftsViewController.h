//
//  PagesDraftsViewController.h
//  WordPress
//
//  Created by JanakiRam on 06/11/08.
//

#import <UIKit/UIKit.h>


@class BlogDataManager, PagesViewController;
@interface PagesDraftsViewController : UITableViewController 
{
	BlogDataManager *dm;
	PagesViewController *pagesListController;
}
@property (nonatomic, assign) PagesViewController *pagesListController;
@end
