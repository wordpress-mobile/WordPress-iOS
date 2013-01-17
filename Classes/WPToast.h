//
//  WPToast.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 1/8/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WPToast : NSObject

+ (void)showToastWithMessage:(NSString *)message andImage:(UIImage *)image;

@end
