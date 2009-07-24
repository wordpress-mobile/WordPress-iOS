//
//  DashboardViewController.h
//  WordPress
//
//  Created by Gareth Townsend on 23/07/09.
//

#import <UIKit/UIKit.h>
#import "RefreshButtonView.h"

@interface DashboardViewController : UIViewController <UITableViewDataSource> {
@private
    IBOutlet UITableView *commentsTableView;
    
    RefreshButtonView *refreshButton;

    BOOL editing;
    
    NSMutableArray *commentsArray;
    NSMutableDictionary *commentsDict;
    
    UIAlertView *progressAlert;
    
    NSMutableArray *sectionHeaders;
}

@property (nonatomic, retain) NSMutableArray *commentsArray;
@property (nonatomic, retain) NSMutableArray *sectionHeaders;

@end