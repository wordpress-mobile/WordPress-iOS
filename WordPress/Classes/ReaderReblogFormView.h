//
//  ReaderReblogFormView.h
//  WordPress
//
//  Created by Eric J on 6/6/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderTextFormView.h"
#import "ReaderPost.h"

@interface ReaderReblogFormView : ReaderTextFormView

@property (nonatomic, strong) ReaderPost *post;

+ (CGFloat)desiredHeight;

@end
