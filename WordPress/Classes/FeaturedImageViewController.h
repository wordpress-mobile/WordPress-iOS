//
//  FeaturedImageViewController.h
//  WordPress
//
//  Created by Eric Johnson on 1/28/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "WPImageViewController.h"
#import "Post.h"

@interface FeaturedImageViewController : WPImageViewController

- (id)initWithPost:(Post *)post;

@end
