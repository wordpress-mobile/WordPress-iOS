#import "WPXMLValidator.h"


@implementation WPXMLValidator

+ (WPXMLValidator *)sharedValidator
{
	static WPXMLValidator *sharedValidator = nil;
	if( sharedValidator == nil )
	{
		sharedValidator = [[WPXMLValidator alloc] init];
	}
	return sharedValidator;
}

- (BOOL)isValidXMLString:(NSString *)aStr
{
	// patch until we can figure out what to do with the <br> fix.
	return YES;
	
	
	
	
	
	if( aStr != nil && [aStr length] > 0 )
	{
		const char *utf8str = [aStr UTF8String];
		NSData *data = [NSData dataWithBytes:utf8str length:strlen(utf8str)];
		NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
		[parser setDelegate:self];
		BOOL parseStatus = [parser parse];
		
		
		if( parseStatus == NO ) {
			NSString *invalidXML = [NSString stringWithFormat:@"Post does not contain valid XHTML. Please review and correct."];
			UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"INVALID XHTML"
															 message:invalidXML
															delegate:self 
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil];
			
			[alert1 show];
			WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
			[delegate setAlertRunning:YES];

			[alert1 release];		
			
			
		}
			
					

		[parser release];
		return parseStatus;
	}
	
	//default NO/YES ?
	return YES;
}


@end
