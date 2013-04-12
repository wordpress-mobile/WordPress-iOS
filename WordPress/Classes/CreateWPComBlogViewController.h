//
//  CreateWPComBlogViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/10/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CreateWPComBlogViewControllerDelegate;
@interface CreateWPComBlogViewController : UITableViewController

@property (nonatomic, weak) id <CreateWPComBlogViewControllerDelegate> delegate;

@end

@protocol CreateWPComBlogViewControllerDelegate <NSObject>

- (void)createdBlogWithDetails:(NSDictionary *)blogDetails;

@end