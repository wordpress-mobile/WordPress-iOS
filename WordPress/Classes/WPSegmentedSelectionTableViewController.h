//
//  WPSegmentedSelectionTableViewController.h
//  WordPress
//
//  Created by Janakiram on 16/09/08.
//

#import <UIKit/UIKit.h>
#import "WPSelectionTableViewController.h"

@interface WPSegmentedSelectionTableViewController : WPSelectionTableViewController {
    NSMutableDictionary *categoryIndentationLevelsDict;
    UIColor *rowTextColor;
}

- (UITableViewCellAccessoryType)accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath ofTableView:(UITableView *)tableView;
- (void)handleNewCategory:(NSNotification *)notification;

@end
