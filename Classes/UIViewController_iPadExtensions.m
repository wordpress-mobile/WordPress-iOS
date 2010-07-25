//
//  UIViewController_iPadExtensions.m
//  WordPress
//
//  Created by Jonathan Wight on 03/30/10.
//  Copyright 2010 toxicsoftware.com. All rights reserved.
//

#import "UIViewController_iPadExtensions.h"

#include <objc/runtime.h>

void Swizzle(Class inClass, SEL inOldSelector, SEL inNewSelector, IMP *outOldImplementation)
{
Method theOriginalMethod = class_getInstanceMethod(inClass, inOldSelector);
IMP theOldImplementation = method_getImplementation(theOriginalMethod);
if (outOldImplementation)
	*outOldImplementation = theOldImplementation;
Method theNewMethod = class_getInstanceMethod(inClass, inNewSelector);
IMP theNewImplementation = method_getImplementation(theNewMethod);
if (class_addMethod(inClass, inOldSelector, theNewImplementation, method_getTypeEncoding(theNewMethod)))
	class_replaceMethod(inClass, inNewSelector, theOldImplementation, method_getTypeEncoding(theOriginalMethod));
else
	method_exchangeImplementations(theOriginalMethod, theNewMethod);
}

#pragma mark -

@implementation UIViewController (UIViewController_iPadExtensions)

+ (void)youWillAutorotateOrYouWillDieMrBond {
	//NSLog(@"youWillAutorotateOrYouWillDieMrBond");
	Swizzle([NSClassFromString(@"UISplitViewController") class], @selector(shouldAutorotateToInterfaceOrientation:), @selector(MyShouldAutorotateToInterfaceOrientation:), NULL);
}

- (BOOL)MyShouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	//NSLog(@"MyShouldAutorotateToInterfaceOrientation (%@)", self);
	return(YES);
}

@end
