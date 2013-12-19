//
//  WPKeyboardToolbarButtonItem.h
//  WordPress
//
//  Created by Jorge Bernal on 8/11/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WPKeyboardToolbarButtonItem : UIButton

@property (nonatomic, strong) NSString *actionTag, *actionName;

+ (id)button;
- (void)setImageName:(NSString *)imageName;
- (void)setImageName:(NSString *)imageName withColor:(UIColor *)tintColor highlightColor:(UIColor *)highlightColor;

@end
