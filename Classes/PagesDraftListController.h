//
//  PagesDraftListController.h
//  WordPress
//
//  Created by JanakiRam on 06/11/08.
//

#import <UIKit/UIKit.h>


@class BlogDataManager, PagesListController;
@interface PagesDraftListController : UITableViewController 
{
	BlogDataManager *dm;
	PagesListController *pagesListController;
}
@property (nonatomic, assign) PagesListController *pagesListController;
@end
