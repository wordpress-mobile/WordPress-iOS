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

@interface ReaderVideoView : ReaderMediaView

@property (readonly, nonatomic, assign) ReaderVideoContentType contentType;
@property (nonatomic, strong) NSString *title;

- (void)setContentURL:(NSURL *)url
			   ofType:(ReaderVideoContentType)type
			  success:(void (^)(id videoView))success
			  failure:(void (^)(id videoView, NSError *error))failure;

@end
