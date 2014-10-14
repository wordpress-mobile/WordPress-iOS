#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>

@interface WPUITestCase : KIFTestCase

- (void) login;
- (void) loginOther;
- (void) logout;

@end