#import "UIWebView+CustomInputAccessoryView.h"
#import <objc/runtime.h>

@implementation UIWebView (CustomInputAccessoryView)

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

- (id)methodReturningCustomInpuAccessoryView
{
    return [(UIWebView*)self.superview.superview customInputAccessoryView];
}

- (void)ensureFixedSubclassExistsOfBrowserViewClass:(Class)browserViewClass
{
    if (!fixClass) {
        Class newClass = objc_allocateClassPair(browserViewClass, fixedClassName, 0);
        //newClass = objc_allocateClassPair(browserViewClass, fixedClassName, 0);
        IMP newImp = [self methodForSelector:@selector(methodReturningCustomInpuAccessoryView)];
        class_addMethod(newClass, @selector(inputAccessoryView), newImp, "@@:");
        objc_registerClassPair(newClass);
        
        fixClass = newClass;
    }
}

- (BOOL)usesCustomInputAccessoryView
{
    UIView *browserView = [self browserView];
    return [browserView class] == fixClass;
}

- (void)setUsesCustomInputAccessoryView:(BOOL)value
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
	if (view) {
		[self setUsesCustomInputAccessoryView:YES];
	} else {
		[self setUsesCustomInputAccessoryView:NO];
	}
	
	objc_setAssociatedObject(self,
							 kCustomInputAccessoryView,
							 view,
							 OBJC_ASSOCIATION_RETAIN);
}

@end
