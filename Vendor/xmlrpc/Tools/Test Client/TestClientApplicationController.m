#import "TestClientApplicationController.h"
#import "TestClientMainWindowController.h"
#import "TestClientXMLParserWindowController.h"

@implementation TestClientApplicationController

- (void)applicationDidFinishLaunching: (NSNotification *)notification {
    [self toggleTestClientWindow: self];
}

#pragma mark -

- (void)toggleTestClientWindow: (id)sender {
    [[TestClientMainWindowController sharedController] toggleTestClientWindow: self];
}

- (void)toggleXMLParserWindow: (id)sender {
    [[TestClientXMLParserWindowController sharedController] toggleXMLParserWindow: self];
}

@end
