//
//  StatsCategoryViewController.h
//  WordPress
//
//  Created by Chris Boyd on 6/18/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StatsCollection.h"

@interface StatsCategoryViewController : UITableViewController {
	StatsCollection *items;
}

@property (nonatomic, retain) StatsCollection *items;

@end
