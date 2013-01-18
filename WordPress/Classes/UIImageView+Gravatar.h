//
//  UIImageView+Gravatar.h
//  WordPress
//
//  Created by Jorge Bernal on 11/4/11.
//  Copyright (c) 2011 WordPress. All rights reserved.
//



@interface UIImageView (Gravatar)

- (void)setImageWithGravatarEmail:(NSString *)emailAddress;
- (void)setImageWithBlavatarUrl:(NSString *)blavatarUrl;
- (void)setImageWithBlavatarUrl:(NSString *)blavatarUrl isWPcom:(BOOL)wpcom;

@end
