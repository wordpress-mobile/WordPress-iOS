//
//  UIImageView+AFNetworkingExtra.h
//  WordPress
//
//  Created by Eric J on 6/17/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (AFNetworkingExtra)

- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage
				success:(void (^)(UIImage *image))success
				failure:(void (^)(NSError *error))failure;

@end
