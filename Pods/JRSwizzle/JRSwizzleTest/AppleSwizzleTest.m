#import "AppleSwizzleTest.h"
#import <objc/runtime.h>

BOOL aFooCalled, bFooCalled, bAltFooCalled;

@interface A5 : NSObject {}
- (void)foo5;
@end
@implementation A5
- (void)foo5 {
	aFooCalled = YES;
}
@end

@interface B5 : A5 {}
@end
@implementation B5
- (void)foo5 {
	bFooCalled = YES;
}
@end

@interface B5 (altFoo5)
- (void)altFoo5;
@end
@implementation B5 (altFoo5)
- (void)altFoo5 {
	bAltFooCalled = YES;
}
@end

@interface A6 : NSObject {}
- (void)foo6;
@end
@implementation A6
- (void)foo6 {
	aFooCalled = YES;
}
@end

@interface B6 : A6 {}
@end
@implementation B6
@end

@interface B6 (altFoo6)
- (void)altFoo6;
@end
@implementation B6 (altFoo6)
- (void)altFoo6 {
	bAltFooCalled = YES;
}
@end

@implementation AppleSwizzleTest

- (void)testAppleSwizzleOfDirectMethod {
	A5 *a = [[[A5 alloc] init] autorelease];
	B5 *b = [[[B5 alloc] init] autorelease];
	
	{
		aFooCalled = bFooCalled = bAltFooCalled = NO;
		[a foo5];
		STAssertTrue(aFooCalled, nil);
		STAssertFalse(bFooCalled, nil);
		STAssertFalse(bAltFooCalled, nil);
		
		aFooCalled = bFooCalled = bAltFooCalled = NO;
		[b foo5];
		STAssertFalse(aFooCalled, nil);
		STAssertTrue(bFooCalled, nil);
		STAssertFalse(bAltFooCalled, nil);
	}
	
	method_exchangeImplementations(class_getInstanceMethod([B5 class], @selector(foo5)),
								   class_getInstanceMethod([B5 class], @selector(altFoo5)));
	
	{
		aFooCalled = bFooCalled = bAltFooCalled = NO;
		[a foo5];
		STAssertTrue(aFooCalled, nil);
		STAssertFalse(bFooCalled, nil);
		STAssertFalse(bAltFooCalled, nil);
		
		aFooCalled = bFooCalled = bAltFooCalled = NO;
		[b foo5];
		STAssertFalse(aFooCalled, nil);
		STAssertFalse(bFooCalled, nil);
		STAssertTrue(bAltFooCalled, nil);
	}
}

- (void)testAppleSwizzleOfInheritedMethod {
	A6 *a = [[[A6 alloc] init] autorelease];
	B6 *b = [[[B6 alloc] init] autorelease];
	
	{
		aFooCalled = bFooCalled = bAltFooCalled = NO;
		[a foo6];
		STAssertTrue(aFooCalled, nil);
		STAssertFalse(bFooCalled, nil);
		STAssertFalse(bAltFooCalled, nil);
		
		aFooCalled = bFooCalled = bAltFooCalled = NO;
		[b foo6];
		STAssertTrue(aFooCalled, nil);
		STAssertFalse(bFooCalled, nil);
		STAssertFalse(bAltFooCalled, nil);
	}
	
	method_exchangeImplementations(class_getInstanceMethod([B6 class], @selector(foo6)),
								   class_getInstanceMethod([B6 class], @selector(altFoo6)));
	
	{
		aFooCalled = bFooCalled = bAltFooCalled = NO;
		[a foo6];
		STAssertFalse(aFooCalled, nil); // KNOWN INCORRECT BEHAVIOR: [a foo6] resulted in calling B6(altFoo6)'s -altFoo6!
		STAssertFalse(bFooCalled, nil);
		STAssertTrue(bAltFooCalled, nil);
		
		aFooCalled = bFooCalled = bAltFooCalled = NO;
		[b foo6];
		STAssertFalse(aFooCalled, nil);
		STAssertFalse(bFooCalled, nil);
		STAssertTrue(bAltFooCalled, nil);
	}
}

@end
