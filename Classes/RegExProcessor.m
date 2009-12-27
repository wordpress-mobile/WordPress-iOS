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
		
	NSLog(@"searchString: '%@'", searchString);
	
	NSLog(@"regexString1 : '%@'", regexString1); 
	NSLog(@"regexString2 : '%@'", regexString2); 
	
	matchArray = [searchString componentsMatchedByRegex:regexString1]; // ≥ 3.0  
	matchEnumerator = [matchArray objectEnumerator]; // ≥ 3.0  
	NSUInteger line = 0UL; 
	NSString *matchedString = NULL; 
	while((matchedString = [matchEnumerator nextObject]) != NULL) 
	{ 
		NSLog(@"The Matched String %lu: %lu '%@'", (u_long)++line, (u_long)[matchedString length], matchedString);
		//returnString = [matchedString stringByMatching:regexString2 capture:2L];
		returnString = [matchedString stringByMatching:regexString2];
		NSLog(@"The Returned String %lu: %lu '%@'", (u_long)++line, (u_long)[returnString length], returnString);
		
		NSLog(@"returnString equals %@", returnString);	} 
	return returnString;
}


@end
