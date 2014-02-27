//
//  ReaderDiscoveryViewController.h
//  WordPress
//
//  Created by Eric Johnson on 1/15/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "ReaderPostsViewController.h"
#import "RecommendedBlog.h"

@interface ReaderDiscoveryViewController : ReaderPostsViewController

@property (nonatomic, strong) RecommendedBlog *recommendedBlog;

@end
