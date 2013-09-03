//
//  UIBarButtonItem+CapitalizedTitles.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/29/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "UIBarButtonItem+CapitalizedTitles.h"
#import <objc/runtime.h>


@implementation UIBarButtonItem (CapitalizedTitles)

- (void)alteredSetTitle:(NSString *)title
{
    // Since we exchanged implementations, this actually calls UIBarButtonItem's setTitle
    NSString *alteredTitle = title;
    if (IS_IOS7) {
        alteredTitle = [title uppercaseString];
    }
    [self alteredSetTitle:alteredTitle];
}

+ (void)load
{
    Method origMethod = class_getInstanceMethod(self, @selector(setTitle:));
    Method newMethod = class_getInstanceMethod(self, @selector(alteredSetTitle:));
    method_exchangeImplementations(origMethod, newMethod);
}

@end
