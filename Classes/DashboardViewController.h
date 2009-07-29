//
//  DashboardViewController.h
//  WordPress
//
//  Created by Gareth Townsend on 23/07/09.
//

#import <UIKit/UIKit.h>
#import "RefreshButtonView.h"

@interface DashboardViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate> {
@private
    RefreshButtonView *refreshButton;

    BOOL editing;
    
    NSMutableArray *comments;
    NSMutableDictionary *commentsMap;
    
    UIAlertView *progressAlert;
    
    NSMutableArray *sectionHeaders;
}

@property (nonatomic, retain) NSMutableArray *comments;
@property (nonatomic, retain) NSMutableArray *sectionHeaders;

@end