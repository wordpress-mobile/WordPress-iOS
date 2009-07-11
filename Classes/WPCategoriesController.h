//
//  WPCategoriesController.h
//  WordPress
//
//  Created by Praveen on 25/06/08.
//

#import <UIKit/UIKit.h>
#import "PostDetailViewController.h"

@interface WPCategoriesController : UIViewController
{
    IBOutlet UITableView *categoriesTableView;
    NSArray *categories;    //just keeping a pointer to the categoies in the current blog
    PostDetailViewController *postDetailViewController;
}

@property (nonatomic, assign) PostDetailViewController *postDetailViewController;

- (void)refreshData;

@end
