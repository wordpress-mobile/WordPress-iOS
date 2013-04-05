//
//  CreateWPComBlogViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/1/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CreateWPComBlogViewControllerDelegate;
@interface CreateWPComBlogViewController : UIViewController

@property (nonatomic, weak) id<CreateWPComBlogViewControllerDelegate> delegate;

@end

@protocol CreateWPComBlogViewControllerDelegate

- (void)createdBlogWithDetails:(NSDictionary *)blogDetails;

@end
