#import "UIWebView+AccessoryHiding.h"
#import <objc/runtime.h>

@implementation UIWebView (AccessoryHiding)

static const char * const fixedClassName = "UIWebBrowserViewMinusAccessoryView";
static Class fixClass = Nil;

- (UIView *)foundBrowserView
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

- (id)methodReturningNil
{
    return nil;
}

- (void)ensureFixedSubclassExistsOfBrowserViewClass:(Class)browserViewClass
{
    if (!fixClass) {
        Class newClass = objc_allocateClassPair(browserViewClass, fixedClassName, 0);
        newClass = objc_allocateClassPair(browserViewClass, fixedClassName, 0);
        IMP nilImp = [self methodForSelector:@selector(methodReturningNil)];
        class_addMethod(newClass, @selector(inputAccessoryView), nilImp, "@@:");
        objc_registerClassPair(newClass);
        
        fixClass = newClass;
    }
}

- (BOOL) hidesInputAccessoryView
{
    UIView *browserView = [self foundBrowserView];
    return [browserView class] == fixClass;
}

- (void) setHidesInputAccessoryView:(BOOL)value
{
    UIView *browserView = [self foundBrowserView];
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

@end
