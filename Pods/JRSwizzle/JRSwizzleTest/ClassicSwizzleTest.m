#import "ClassicSwizzleTest.h"
#import <objc/objc-class.h>

//	Lifted from http://www.cocoadev.com/index.pl?MethodSwizzling
void ClassicMethodSwizzle(Class aClass, SEL orig_sel, SEL alt_sel) {
    Method orig_method = nil, alt_method = nil;
	
    // First, look for the methods
    orig_method = class_getInstanceMethod(aClass, orig_sel);
    alt_method = class_getInstanceMethod(aClass, alt_sel);
	
    // If both are found, swizzle them
    if ((orig_method != nil) && (alt_method != nil))
	{
        char *temp1;
        IMP temp2;
		
        temp1 = orig_method->method_types;
        orig_method->method_types = alt_method->method_types;
        alt_method->method_types = temp1;
		
        temp2 = orig_method->method_imp;
        orig_method->method_imp = alt_method->method_imp;
        alt_method->method_imp = temp2;
	}
}

BOOL aFooCalled, bFooCalled, bAltFooCalled;

@interface A1 : NSObject {}
- (void)foo1;
@end
@implementation A1
- (void)foo1 {
	aFooCalled = YES;
}
@end

@interface B1 : A1 {}
@end
@implementation B1
- (void)foo1 {
	bFooCalled = YES;
}
@end

@interface B1 (altFoo1)
- (void)altFoo1;
@end
@implementation B1 (altFoo1)
- (void)altFoo1 {
	bAltFooCalled = YES;
}
@end

@interface A2 : NSObject {}
- (void)foo2;
@end
@implementation A2
- (void)foo2 {
	aFooCalled = YES;
}
@end

@interface B2 : A2 {}
@end
@implementation B2
@end

@interface B2 (altFoo2)
- (void)altFoo2;
@end
@implementation B2 (altFoo2)
- (void)altFoo2 {
	bAltFooCalled = YES;
}
@end

@implementation ClassicSwizzleTest

- (void)testClassicSwizzleOfDirectMethod {
	A1 *a = [[[A1 alloc] init] autorelease];
	B1 *b = [[[B1 alloc] init] autorelease];
	
	{
		aFooCalled = bFooCalled = bAltFooCalled = NO;
		[a foo1];
		STAssertTrue(aFooCalled, nil);
		STAssertFalse(bFooCalled, nil);
		STAssertFalse(bAltFooCalled, nil);
		
		aFooCalled = bFooCalled = bAltFooCalled = NO;
		[b foo1];
		STAssertFalse(aFooCalled, nil);
		STAssertTrue(bFooCalled, nil);
		STAssertFalse(bAltFooCalled, nil);
	}
	
	ClassicMethodSwizzle([B1 class], @selector(foo1), @selector(altFoo1));
	
	{
		aFooCalled = bFooCalled = bAltFooCalled = NO;
		[a foo1];
		STAssertTrue(aFooCalled, nil);
		STAssertFalse(bFooCalled, nil);
		STAssertFalse(bAltFooCalled, nil);
		
		aFooCalled = bFooCalled = bAltFooCalled = NO;
		[b foo1];
		STAssertFalse(aFooCalled, nil);
		STAssertFalse(bFooCalled, nil);
		STAssertTrue(bAltFooCalled, nil);
	}
}

- (void)testClassicSwizzleOfInheritedMethod {
	A2 *a = [[[A2 alloc] init] autorelease];
	B2 *b = [[[B2 alloc] init] autorelease];
	
	{
		aFooCalled = bFooCalled = bAltFooCalled = NO;
		[a foo2];
		STAssertTrue(aFooCalled, nil);
		STAssertFalse(bFooCalled, nil);
		STAssertFalse(bAltFooCalled, nil);
		
		aFooCalled = bFooCalled = bAltFooCalled = NO;
		[b foo2];
		STAssertTrue(aFooCalled, nil);
		STAssertFalse(bFooCalled, nil);
		STAssertFalse(bAltFooCalled, nil);
	}
	
	ClassicMethodSwizzle([B2 class], @selector(foo2), @selector(altFoo2));
	
	{
		aFooCalled = bFooCalled = bAltFooCalled = NO;
		[a foo2];
		STAssertFalse(aFooCalled, nil); // KNOWN INCORRECT BEHAVIOR: [a foo2] resulted in calling B2(altFoo2)'s -altFoo2!
		STAssertFalse(bFooCalled, nil);
		STAssertTrue(bAltFooCalled, nil);
		
		aFooCalled = bFooCalled = bAltFooCalled = NO;
		[b foo2];
		STAssertFalse(aFooCalled, nil);
		STAssertFalse(bFooCalled, nil);
		STAssertTrue(bAltFooCalled, nil);
	}
}

@end
