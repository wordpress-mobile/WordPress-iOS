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

@interface ___FILEBASENAMEASIDENTIFIER___ViewController ()
// Connect IBOutlets here.
@end

@implementation ___FILEBASENAMEASIDENTIFIER___ViewController

+ (NSString *)nibNameForTestCase:(SEL)testCase {
    return @"___FILEBASENAMEASIDENTIFIER___ViewController";
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
// Put any app hooks below here

@end
