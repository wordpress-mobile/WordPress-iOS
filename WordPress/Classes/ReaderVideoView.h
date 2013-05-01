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
@property (readonly, nonatomic, strong) NSObject *content;
@property (readonly, nonatomic, assign) ReaderVideoContentType contentType;


/**
 All three properties should be set, and order may matter.  This is a convenience function for this purpose.
 */
- (void)setContentURL:(NSURL *)url andContent:(NSObject *)content ofType:(ReaderVideoContentType)type;
- (UIImage *)image;

@end
