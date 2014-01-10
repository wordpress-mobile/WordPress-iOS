//
//  PostFeaturedImageCell.m
//  WordPress
//
//  Created by Eric Johnson on 1/9/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "PostFeaturedImageCell.h"

@interface PostFeaturedImageCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@property (nonatomic, strong) UILabel *statusLabel;

@end

@implementation PostFeaturedImageCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
        self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, 44.0f)];
        self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return self;
}

- (void)setImageURL:(NSString *)imageURL {
    
}

- (CGFloat)desiredHeightForWidth:(CGFloat)width {
    
    if (self.imageView.image) {
        CGSize size = self.imageView.image.size;
        if (size.height > 0.0f) {
            return ceilf(width * (size.width / size.height));
        }
    }
    return 44.0f;
}

@end
