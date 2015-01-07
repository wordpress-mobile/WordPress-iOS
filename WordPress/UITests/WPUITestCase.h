#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import <KIFUITestActor-IdentifierTests.h>
#import "KIFUITestActor-WPExtras.h"

@interface WPUITestCase : KIFTestCase

- (void) login;
- (void) loginOther;
- (void) logout;
- (void) logoutIfNeeded;

@end