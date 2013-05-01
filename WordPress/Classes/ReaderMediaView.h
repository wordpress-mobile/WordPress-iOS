//
//  ReaderMediaView.h
//  WordPress
//
//  Created by Eric J on 4/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ReaderMediaView <NSObject>

@property (nonatomic, assign) UIEdgeInsets edgeInsets;

- (UIImage *)image;
- (NSURL *)contentURL;

@end
