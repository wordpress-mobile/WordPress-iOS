//
//  ReaderAttributionView.h
//  WordPress
//
//  Created by Eric Johnson on 1/14/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContentActionButton.h"

@interface ReaderAttributionView : UIView

@property (nonatomic, weak) NSString *authorName;
@property (nonatomic, weak) NSString *authorLink;
@property (nonatomic, strong, readonly) UIImageView *avatarImageView;
@property (nonatomic, strong, readonly) UIButton *linkButton;
@property (nonatomic, strong, readonly) ContentActionButton *followButton;

- (void)setAuthorDisplayName:(NSString *)authorName authorLink:(NSString *)authorLink;

@end
