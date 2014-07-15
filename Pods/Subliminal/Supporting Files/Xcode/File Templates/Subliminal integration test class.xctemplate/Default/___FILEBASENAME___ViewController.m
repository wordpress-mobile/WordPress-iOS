//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//___COPYRIGHT___
//

#import "SLTestCaseViewController.h"

#import <Subliminal/SLTestController+AppHooks.h>

@interface ___FILEBASENAMEASIDENTIFIER___ViewController : SLTestCaseViewController

@end

@implementation ___FILEBASENAMEASIDENTIFIER___ViewController

/**
 For every test case, EITHER return a non-nil value from nibNameForTestCase: 
 OR set self.view in loadViewForTestCase:.
 */

+ (NSString *)nibNameForTestCase:(SEL)testCase {
#warning Potentially incomplete method implementation.
    // Return the name of the nib file which contains the view
    // to be exercised by testCase.
    return nil;
}

- (void)loadViewForTestCase:(SEL)testCase {
#warning Potentially incomplete method implementation.
    // Create the view hierarchy to be exercised by testCase 
    // and assign the root view of the hierarchy to self.view.
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
    // Test case specific configuration is best done using app hooks
    // triggered from -[___FILEBASENAMEASIDENTIFIER___ setUpTestCaseWithSelector:].
}

- (instancetype)initWithTestCaseWithSelector:(SEL)testCase {
    self = [super initWithTestCaseWithSelector:testCase];
    if (self) {
        // Register for app hooks, e.g.
        // [[SLTestController sharedTestController] registerTarget:<#(id)#> forAction:<#(SEL)#>];
    }
    return self;
}

// Deregister for app hooks, if any
//- (void)dealloc {
//    [[SLTestController sharedTestController] deregisterTarget:self];
//}

//#pragma mark - App hooks
//Put any app hooks below here

@end
