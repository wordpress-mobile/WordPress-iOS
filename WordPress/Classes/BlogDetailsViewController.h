//
//  BlogDetailsViewController.h
//  WordPress
//
//  Created by Michael Johnston on 11/9/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Blog;

@interface BlogDetailsViewController : UITableViewController <UIViewControllerRestoration> {
    
}

@property (nonatomic, strong) Blog *blog;

@end
