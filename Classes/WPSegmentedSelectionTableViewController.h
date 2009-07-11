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

//@property (nonatomic, retain) NSArray *objects;
//@property (nonatomic, retain) NSMutableArray *selectionStatusOfObjects;
//@property (nonatomic, retain) NSMutableArray *originalSelObjects;

- (UITableViewCellAccessoryType)accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath ofTableView:(UITableView *)tableView;

@end
