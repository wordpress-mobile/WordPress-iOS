//
//  PostSettingsHelpViewController.h
//  WordPress
//
//  Created by Christopher Boyd on 2/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"

@interface PostSettingsHelpViewController : UITableViewController {
	NSMutableDictionary *helpContent;
}

@property (nonatomic, retain) NSMutableDictionary *helpContent;

@end
