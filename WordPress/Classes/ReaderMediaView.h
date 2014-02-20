//
//  ReaderMediaView.h
//  WordPress
//
//  Created by Eric J on 4/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ReaderMediaView : UIControl

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) UIEdgeInsets edgeInsets;
@property (nonatomic, strong) NSURL *contentURL;
@property (nonatomic) BOOL isShowingPlaceholder;

- (UIImage *)image;
- (void)setImage:(UIImage *)image;
- (NSURL *)contentURL;
- (void)setPlaceholder:(UIImage *)image;
- (void)setImageWithURL:(NSURL *)url
	   placeholderImage:(UIImage *)image
				success:(void (^)(ReaderMediaView *readerMediaView))success
				failure:(void (^)(ReaderMediaView *readerMediaView, NSError *error))failure;
@end
