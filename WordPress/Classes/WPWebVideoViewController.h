//
//  WPWebVideoViewController.h
//  WordPress
//
//  Created by Eric J on 5/14/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WPWebVideoViewController : UIViewController

+ (id)presentAsModalWithURL:(NSURL *)url;
+ (id)presentAsModalWithHTML:(NSString *)html;

- (id)initWithURL:(NSURL *)url;
- (id)initWithHTML:(NSString *)html;

@end
