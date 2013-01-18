#import <Cocoa/Cocoa.h>

@interface TestClientXMLParserWindowController : NSWindowController {
    id myParsedObject;
    IBOutlet NSTextView *myXML;
    IBOutlet NSOutlineView *myParserResult;
}

+ (TestClientXMLParserWindowController *)sharedController;

#pragma mark -

- (void)showXMLParserWindow: (id)sender;

- (void)hideXMLParserWindow: (id)sender;

#pragma mark -

- (void)toggleXMLParserWindow: (id)sender;

#pragma mark -

- (void)parse: (id)sender;

@end
