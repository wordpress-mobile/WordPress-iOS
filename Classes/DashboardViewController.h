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
    
    NSArray *comments;
    NSDictionary *commentsMap;
    NSArray *commentsSections;
	UISegmentedControl *segmentedControl;
    
    UIAlertView *progressAlert;
}

@property (nonatomic, retain) NSArray *comments;
@property (nonatomic, retain) NSDictionary *commentsMap;
@property (nonatomic, retain) NSArray *commentsSections;
@property (nonatomic, retain) UISegmentedControl *segmentedControl;


@end