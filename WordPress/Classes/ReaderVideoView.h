//
//  ReaderVideoView.h
//  WordPress
//
//  Created by Eric J on 4/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderMediaView.h"

typedef enum {
    ReaderVideoContentTypeVideo,
    ReaderVideoContentTypeIFrame,
    ReaderVideoContentTypeEmbed
} ReaderVideoContentType;

@interface ReaderVideoView : UIControl <ReaderMediaView>

@property (nonatomic, assign) UIEdgeInsets edgeInsets;
@property (readonly, nonatomic, strong) NSURL *contentURL;
@property (readonly, nonatomic, assign) ReaderVideoContentType contentType;
@property (nonatomic, strong) NSString *title;


- (void)setContentURL:(NSURL *)url
			   ofType:(ReaderVideoContentType)type
			  success:(void (^)(ReaderVideoView *videoView))success
			  failure:(void (^)(ReaderVideoView *videoView, NSError *error))failure;

- (void)setImageWithURL:(NSURL *)url
	   placeholderImage:(UIImage *)image
				success:(void (^)(ReaderVideoView *videoView))success
				failure:(void (^)(ReaderVideoView *videoView, NSError *error))failure;


@end
