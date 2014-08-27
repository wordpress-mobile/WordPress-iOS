#import "UIWebView+GUIFixes.h"
#import <objc/runtime.h>

@implementation UIWebView (GUIFixes)

static const char* const kCustomInputAccessoryView = "kCustomInputAccessoryView";
static const char* const fixedClassName = "UIWebBrowserViewMinusAccessoryView";
static Class fixClass = Nil;

- (UIView *)browserView
{
    UIScrollView *scrollView = self.scrollView;
    
    UIView *browserView = nil;
    for (UIView *subview in scrollView.subviews) {
        if ([NSStringFromClass([subview class]) hasPrefix:@"UIWebBrowserView"]) {
            browserView = subview;
            break;
        }
    }
	
    return browserView;
}

- (id)methodReturningCustomInputAccessoryView
{
	UIView* view = [self performSelector:@selector(originalInputAccessoryView) withObject:nil];
	
	if (view) {
		
		UIView* parentWebView = self.superview;
		
		while (parentWebView && ![parentWebView isKindOfClass:[UIWebView class]])
		{
			parentWebView = parentWebView.superview;
		}
		
		view = [(UIWebView*)parentWebView customInputAccessoryView];
	} else {
		int i = 1;
		i++;
	}
	
	return view;
}

- (BOOL)delayedBecomeFirstResponder
{
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[super becomeFirstResponder];
	});
	
	return YES;
}

- (void)ensureFixedSubclassExistsOfBrowserViewClass:(Class)browserViewClass
{
    if (!fixClass) {
        Class newClass = objc_allocateClassPair(browserViewClass, fixedClassName, 0);
		IMP oldImp = class_getMethodImplementation(browserViewClass, @selector(inputAccessoryView));
		class_addMethod(newClass, @selector(originalInputAccessoryView), oldImp, "@@:");
		
        IMP newImp = [self methodForSelector:@selector(methodReturningCustomInputAccessoryView)];
        class_addMethod(newClass, @selector(inputAccessoryView), newImp, "@@:");
        objc_registerClassPair(newClass);
		
        IMP delayedFirstResponderImp = [self methodForSelector:@selector(delayedBecomeFirstResponder)];
		Method becomeFirstResponderMethod = class_getInstanceMethod(browserViewClass, @selector(becomeFirstResponder));
		method_setImplementation(becomeFirstResponderMethod, delayedFirstResponderImp);
        
        fixClass = newClass;
    }
}

- (BOOL)usesGUIFixes
{
    UIView *browserView = [self browserView];
    return [browserView class] == fixClass;
}

- (void)setUsesGUIFixes:(BOOL)value
{
    UIView *browserView = [self browserView];
    if (browserView == nil) {
        return;
    }
   
	[self ensureFixedSubclassExistsOfBrowserViewClass:[browserView class]];

    if (value) {
        object_setClass(browserView, fixClass);
    }
    else {
        Class normalClass = objc_getClass("UIWebBrowserView");
        object_setClass(browserView, normalClass);
    }
	
    [browserView reloadInputViews];
}

- (UIView*)customInputAccessoryView
{
	return objc_getAssociatedObject(self, kCustomInputAccessoryView);
}

- (void)setCustomInputAccessoryView:(UIView*)view
{
	objc_setAssociatedObject(self,
							 kCustomInputAccessoryView,
							 view,
							 OBJC_ASSOCIATION_RETAIN);
}

@end
