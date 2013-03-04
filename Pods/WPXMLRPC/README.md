# WordPress XML-RPC Framework

The WordPress XML-RPC library is a lightweight XML-RPC client for iOS
and OS X.

It's based on Eric Czarny's Cocoa XML-RPC Framework, but without all the
networking code, and a few additions of our own.

# Installation

WordPress XML-RPC uses [CocoaPods](http://cocoapods.org/) for easy
dependency management.

Until we are ready for a 1.0 release, you can add this to your Podfile:

	pod 'WPXMLRPC', :podspec => 'https://raw.github.com/wordpress-mobile/wpxmlrpc/master/WPXMLRPC.podspec'

Another option, if you don't use CocoaPods, is to copy the `WPXMLRPC`
folder to your project.

# Usage

WordPress XML-RPC only provides classes to encode and decode XML-RPC. You are free to use your favorite networking library.

## Building a XML-RPC request

	NSURL *URL = [NSURL URLWithString:@"http://example.com/xmlrpc"];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
	[request setHTTPMethod:@"POST"];
	
	WPXMLRPCEncoder *encoder = [[WPXMLRPCEncoder alloc] initWithMethod:@"demo.addTwoNumbers" andParameters:@[@1, @2]];
	[request setHTTPBody:encoder.body];

## Building a XML-RPC request using streaming

	NSURL *URL = [NSURL URLWithString:@"http://example.com/xmlrpc"];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
	[request setHTTPMethod:@"POST"];
	
	NSInputStream *fileStream = [NSInputStream inputStreamWithFileAtPath:filePath];
	WPXMLRPCEncoder *encoder = [[WPXMLRPCEncoder alloc] initWithMethod:@"test.uploadFile" andParameters:@[fileStream]];
	[request setHTTPBodyStream:encoder.bodyStream];
	[request setValue:[encoder.contentLength stringValue] forHTTPHeaderField:@"Content-Length"];

## Parsing a XML-RPC response

	NSData *responseData = …
	WPXMLRPCDecoder *decoder = [WPXMLRPCDecoder alloc] initWithData:responseData];
	if ([decoder isFault]) {
		NSLog(@"XML-RPC error %@: %@", [decoder faultCode], [decoder faultString]);
	} else {
		NSLog(@"XML-RPC response: %@", [decoder object]);
	}

# Acknowledgments

The Base64 encoder/decoder found in NSData+Base64 is created by [Matt Gallagher](http://cocoawithlove.com/2009/06/base64-encoding-options-on-mac-and.html).

The original Cocoa XML-RPC Framework was developed by [Eric Czarny](https://github.com/eczarny/xmlrpc) and now lives at [github.com/corristo/xmlrpc](https://github.com/corristo/xmlrpc)