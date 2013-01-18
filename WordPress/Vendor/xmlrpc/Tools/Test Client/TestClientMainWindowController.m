#import "TestClientMainWindowController.h"

@implementation TestClientMainWindowController

static TestClientMainWindowController *sharedInstance = nil;

- (id)init {
    if ((self = [super initWithWindowNibName: @"TestClientMainWindow"])) {
        myResponse = nil;
    }
    
    return self;
}

#pragma mark -

+ (id)allocWithZone: (NSZone *)zone {
    @synchronized(self) {
        if (!sharedInstance) {
            sharedInstance = [super allocWithZone: zone];
            
            return sharedInstance;
        }
    }
    
    return nil;
}

#pragma mark -

+ (TestClientMainWindowController *)sharedController {
    @synchronized(self) {
        if (!sharedInstance) {
            [[self alloc] init];
        }
    }
    
    return sharedInstance;
}

#pragma mark -

- (void)awakeFromNib {
    [[self window] center];
}

#pragma mark -

- (void)showTestClientWindow: (id)sender {
    [self showWindow: sender];
}

- (void)hideTestClientWindow: (id)sender {
    [self close];
}

#pragma mark -

- (void)toggleTestClientWindow: (id)sender {
    if ([[self window] isKeyWindow]) {
        [self hideTestClientWindow: sender];
    } else {
        [self showTestClientWindow: sender];
    }
}

#pragma mark -

- (void)sendRequest: (id)sender {
	NSURL *URL = [NSURL URLWithString: [myRequestURL stringValue]];	
	XMLRPCRequest *request = [[[XMLRPCRequest alloc] initWithURL: URL] autorelease];
	NSString *connectionIdentifier;
    
    [request setMethod: [myMethod stringValue] withParameter: [myParameter stringValue]];
    
	[myProgressIndicator startAnimation: self];
	
    [myRequestBody setString: [request body]];
    
	connectionIdentifier = [[XMLRPCConnectionManager sharedManager] spawnConnectionWithXMLRPCRequest: request delegate: self];
    
    [myActiveConnection setHidden: NO];
    
    [myActiveConnection setStringValue: [NSString stringWithFormat: @"Active Connection: %@", connectionIdentifier]];
    
    [mySendRequest setEnabled: NO];
}

#pragma mark -

- (void)dealloc {
    [myResponse release];
    
    [super dealloc];
}

#pragma mark -

#pragma mark Outline View Data Source Methods

#pragma mark -

- (id)outlineView: (NSOutlineView *)outlineView child: (NSInteger)index ofItem: (id)item {
    if (item == nil) {
        item = [myResponse object];
    }
    
    if ([item isKindOfClass: [NSDictionary class]]) {
        return [item objectForKey: [[item allKeys] objectAtIndex: index]];
    } else if ([item isKindOfClass: [NSArray class]]) {
        return [item objectAtIndex: index];
    }
    
    return item;
}

- (BOOL)outlineView: (NSOutlineView *)outlineView isItemExpandable: (id)item {
    if ([item isKindOfClass: [NSDictionary class]] || [item isKindOfClass: [NSArray class]]) {
        if ([item count] > 0) {
            return YES;
        }
    }
    
    return NO;
}

- (NSInteger)outlineView: (NSOutlineView *)outlineView numberOfChildrenOfItem: (id)item {
    if (item == nil) {
        item = [myResponse object];
    }
    
    if ([item isKindOfClass: [NSDictionary class]] || [item isKindOfClass: [NSArray class]]) {
        return [item count];
    } else if (item != nil) {
        return 1;
    }
    
    return 0;
}

- (id)outlineView: (NSOutlineView *)outlineView objectValueForTableColumn: (NSTableColumn *)tableColumn byItem: (id)item {
    NSString *columnIdentifier = (NSString *)[tableColumn identifier];
    
    if ([columnIdentifier isEqualToString: @"type"]) {
        id parentObject = [outlineView parentForItem: item] ? [outlineView parentForItem: item] : [myResponse object];
        
        if ([parentObject isKindOfClass: [NSDictionary class]]) {
            return [[parentObject allKeysForObject: item] objectAtIndex: 0];
        } else if ([parentObject isKindOfClass: [NSArray class]]) {
            return [NSString stringWithFormat: @"Item %d", [parentObject indexOfObject: item]];
        } else if ([item isKindOfClass: [NSString class]]) {
            return @"String";
        } else {
            return @"Object";
        }
    } else {
        if ([item isKindOfClass: [NSDictionary class]] || [item isKindOfClass: [NSArray class]]) {
            return [NSString stringWithFormat: @"%d items", [item count]];
        } else {
            return item;
        }
    }
    
    return nil;
}

#pragma mark -

#pragma mark XMLRPC Connection Delegate Methods

#pragma mark -

- (void)request: (XMLRPCRequest *)request didReceiveResponse: (XMLRPCResponse *)response {
    [myProgressIndicator stopAnimation: self];
    
    [myActiveConnection setHidden: YES];
    
    [mySendRequest setEnabled: YES];
	
	if ([response isFault]) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        
        [alert addButtonWithTitle: @"OK"];
        [alert setMessageText: @"The XML-RPC response returned a fault."];
        [alert setInformativeText: [NSString stringWithFormat: @"Fault String: %@", [response faultString]]];
        [alert setAlertStyle: NSCriticalAlertStyle];
        
        [alert runModal];
    } else {
        [response retain];
        
        [myResponse release];
        
        myResponse = response;
    }
    
    [myParsedResponse reloadData];
    
    [myResponseBody setString: [response body]];
}

- (void)request: (XMLRPCRequest *)request didFailWithError: (NSError *)error {
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	
    [[NSApplication sharedApplication] requestUserAttention: NSCriticalRequest];
    
	[alert addButtonWithTitle: @"OK"];
	[alert setMessageText: @"The request failed!"];
	[alert setInformativeText: @"The request failed to return a valid response."];
	[alert setAlertStyle: NSCriticalAlertStyle];
    
	[alert runModal];
    
    [myParsedResponse reloadData];
    
    [myProgressIndicator stopAnimation: self];
	
    [myActiveConnection setHidden: YES];
    
	[mySendRequest setEnabled: YES];
}

- (void)request: (XMLRPCRequest *)request didReceiveAuthenticationChallenge: (NSURLAuthenticationChallenge *)challenge {
	if ([challenge previousFailureCount] == 0) {
		NSURLCredential *credential = [NSURLCredential credentialWithUser: @"user" password: @"password" persistence: NSURLCredentialPersistenceNone];
		
		[[challenge sender] useCredential: credential  forAuthenticationChallenge: challenge];
	} else {
		[[challenge sender] cancelAuthenticationChallenge: challenge];
	}
}

- (void)request: (XMLRPCRequest *)request didCancelAuthenticationChallenge: (NSURLAuthenticationChallenge *)challenge {
	
}

- (BOOL)request: (XMLRPCRequest *)request canAuthenticateAgainstProtectionSpace: (NSURLProtectionSpace *)protectionSpace {
    return NO;
}

@end
