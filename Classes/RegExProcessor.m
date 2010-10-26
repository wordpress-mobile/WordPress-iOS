//
//  RegExProcessor.m
//  WordPress
//
//  Created by John Bickerstaff on 7/11/09.
//  
//

#import "RegExProcessor.h"


@implementation RegExProcessor

- (NSString *) lookForXMLRPCEndpointInURLString:(NSString *) urlString {
	
	NSString * returnString = nil;
	NSString *searchString = urlString;
	NSArray *matchArray = NULL; 
	NSEnumerator *matchEnumerator = NULL; 
	
	NSString *regexString1 = @"rel=\"(EditURI)\"(.+\")";
	NSString *regexString2 = @"(http://)([^\"]+)";
	
	matchArray = [searchString componentsMatchedByRegex:regexString1]; // ≥ 3.0  
	matchEnumerator = [matchArray objectEnumerator]; // ≥ 3.0  
	//NSUInteger line = 0UL; 
	NSString *matchedString = NULL; 
	while((matchedString = [matchEnumerator nextObject]) != NULL) 
	{ 
		returnString = [matchedString stringByMatching:regexString2];
	}
	
	return returnString;
}


@end
