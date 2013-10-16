//
//  PostSettingsSelectionViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/16/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PostSettingsSelectionViewController : UITableViewController

@property (nonatomic, copy) void(^onItemSelected)(NSString *);

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (void)dismiss;

@end
