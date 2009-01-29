//
//  WPSegmentedSelectionTableViewController.h
//  WordPress
//
//  Created by Janakiram on 16/09/08.
//  Copyright 2008 Effigent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WPSelectionTableViewController.h"

@interface WPSegmentedSelectionTableViewController : WPSelectionTableViewController {
	
    NSMutableArray *categoryNames;
	NSMutableArray *categoryIndentationLevels;
}
-(int)indentationLevelForParentIDAndCategoryArray:(NSString *)parentID categoryObjects:(NSArray *)categoryArray;
@end