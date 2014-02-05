//
//  PostFeaturedImageCell.h
//  WordPress
//
//  Created by Eric Johnson on 1/9/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "WPTableViewCell.h"

@interface PostFeaturedImageCell : WPTableViewCell

extern CGFloat const PostFeaturedImageCellMargin;

- (void)setImage:(UIImage *)image;
- (void)showLoadingSpinner:(BOOL)showSpinner;

@end
