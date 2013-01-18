# The Cocoa XML-RPC Framework

The Cocoa XML-RPC Framework is a simple, and lightweight, XML-RPC client framework written in Objective-C.

# Requirements

The Cocoa XML-RPC Framework has been built, and designed, for Mac OS X 10.5 or later. This release should provide basic iPhone and iPod touch support.

This version of the Cocoa XML-RPC Framework includes a new event-based XML parser. The previous tree-based XML parser still exists, but is no longer the default XML-RPC response parser nor included in the Xcode build. This should hopefully provide better compatibility with the iPhone SDK.

# Usage

The following example of the Cocoa XML-RPC Framework assumes that the included XML-RPC test server is available. More information on the test server can be found in the README under:

    XMLRPC\Tools\Test Server

Please review this document before moving forward.

## Invoking XML-RPC requests through the XML-RPC connection manager

Invoking an XML-RPC request through the XML-RPC connection manager is easy:

    NSURL *URL = [NSURL URLWithString: @"http://127.0.0.1:8080/"];	
    XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithURL: URL];
    XMLRPCConnectionManager *manager = [XMLRPCConnectionManager sharedManager];

    [request setMethod: @"Echo.echo" withParameter: @"Hello World!"];

    NSLog(@"Request body: %@", [request body]);

    [manager spawnConnectionWithXMLRPCRequest: request delegate: self];

    [request release];

This spawns a new XML-RPC connection, assigning that connection with a unique identifer and returning it to the sender. This unique identifier, a UUID expressed as an NSString, can then be used to obtain the XML-RPC connection from the XML-RPC connection manager, as long as it is still active.

The XML-RPC connection manager has been designed to ease the management of active XML-RPC connections. For example, the following method obtains an NSArray of active XML-RPC connection identifiers:

    - (NSArray *)activeConnectionIdentifiers;

The NSArray returned by this method contains a list of each active connection identifier. Provided with a connection identifier, the following method will return an instance of the requested XML-RPC connection:

    - (XMLRPCConnection *)connectionForIdentifier: (NSString *)connectionIdentifier;

Finally, for a delegate to receive XML-RPC responses, authentication challenges, or errors, the XMLRPCConnectionDelegate protocol must be implemented. For example, the following will handle successful XML-RPC responses:

    - (void)request: (XMLRPCRequest *)request didReceiveResponse: (XMLRPCResponse *)response {
        if ([response isFault]) {
            NSLog(@"Fault code: %@", [response faultCode]);

            NSLog(@"Fault string: %@", [response faultString]);
        } else {
            NSLog(@"Parsed response: %@", [response object]);
        }

        NSLog(@"Response body: %@", [response body]);
    }

Refer to XMLRPCConnectionDelegate.h for a full list of methods a delegate must implement. Each of these delegate methods plays a role in the life of an active XML-RPC connection.

## Sending synchronous XML-RPC requests

There are situations where it may be desirable to invoke XML-RPC requests synchronously in another thread or background process. The following method declared in XMLRPCConnection.h will invoke an XML-RPC request synchronously:

    + (XMLRPCResponse *)sendSynchronousXMLRPCRequest: (XMLRPCRequest *)request error: (NSError **)error;

If there is a problem sending the XML-RPC request expect nil to be returned.

# What if I find a bug, or what if I want to help?

Please, contact me with any questions, comments, suggestions, or problems. I try to make the time to answer every request.

Those wishing to contribute to the project should begin by obtaining the latest source with Git. The project is hosted on GitHub, making it easy for anyone to make contributions. Simply create a fork and make your changes.

# Acknowledgments

The Base64 encoder/decoder found in NSData+Base64 is created by [Matt Gallagher](http://cocoawithlove.com/2009/06/base64-encoding-options-on-mac-and.html).

The idea for this framework came from examples provided by Brent Simmons, the creator of NetNewsWire.

# License

Copyright (c) 2012 Eric Czarny.

The Cocoa XML-RPC Framework should be accompanied by a LICENSE file, this file contains the license relevant to this distribution.

If no LICENSE exists please contact Eric Czarny <eczarny@gmail.com>.
