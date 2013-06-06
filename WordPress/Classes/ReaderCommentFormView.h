//
//  ReaderCommentFormView.h
//  WordPress
//
//  Created by Eric J on 6/5/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderTextFormView.h"
#import "ReaderPost.h"
#import "ReaderComment.h"

@interface ReaderCommentFormView : ReaderTextFormView

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) ReaderComment *comment;

+ (CGFloat)desiredHeight;

@end
