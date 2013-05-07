//
//  WPWalkthroughButton.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, WPWalkthroughButtonColor) {
    WPWalkthroughButtonBlue,
    WPWalkthroughButtonGray,
};


@interface WPWalkthroughButton : UIControl

@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) WPWalkthroughButtonColor buttonColor;

@end
