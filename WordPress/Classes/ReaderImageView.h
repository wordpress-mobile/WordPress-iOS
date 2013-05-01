//
//  ReaderImageView.h
//  WordPress
//
//  Created by Eric J on 4/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderMediaView.h"

@interface ReaderImageView : UIControl <ReaderMediaView>

@property (nonatomic, assign) UIEdgeInsets edgeInsets;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSURL *contentURL;
@property (nonatomic, strong) NSURL *linkURL;

- (void)setImageWithURL:(NSURL *)url
	   placeholderImage:(UIImage *)image
				success:(void (^)(ReaderImageView *readerImageView))success
				failure:(void (^)(ReaderImageView *readerImageView, NSError *error))failure;
@end
