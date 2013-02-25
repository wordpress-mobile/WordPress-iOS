//
//  UIKitTestHelper.h
//  WordPress
//
//  Created by Jorge Bernal on 2/25/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UITextField (UIKitTestHelper)
- (void)typeText:(NSString *)text;
@end

@interface UITextView (UIKitTestHelper)
- (void)typeText:(NSString *)text;
@end