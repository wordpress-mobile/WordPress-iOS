//
//  CustomFieldsTableView.h
//  WordPress
//
//  Created by John Bickerstaff on 5/5/09.
//  
//

#import <UIKit/UIKit.h>
#import "BlogDataManager.h"
#import "PostViewController.h"
#import "PageViewController.h"
#import "CustomFieldsDetailController.h"

@interface CustomFieldsTableView : UITableViewController {
    CustomFieldsDetailController *customFieldsDetailController;

    PostViewController *postDetailViewController;
    PageViewController *pageDetailsController;

    BlogDataManager *dm;
    NSArray *customFieldsArray;
    IBOutlet UITableView *customFieldsTableView;
    IBOutlet UIBarButtonItem *saveButtonItem;
    BOOL newCustomFieldBool;
    BOOL _isPost;
}

@property (nonatomic, retain) CustomFieldsDetailController *customFieldsDetailController;

@property (nonatomic, assign) PostViewController *postDetailViewController;
@property (nonatomic, assign) PageViewController *pageDetailsController;
@property (nonatomic, assign) BlogDataManager *dm;
@property (nonatomic, retain) NSArray *customFieldsArray;
@property (retain, nonatomic) UITableView *customFieldsTableView;
@property BOOL isPost;

- (void)getCustomFieldsStripMetadata;
- (NSDictionary *)getDictForThisCell:(NSString *)rowString;

@end
