//
//  XMLRPCConnection+Authentication.m
//  WordPress
//
//  Created by Jeff Stieler on 11/17/09.
//

#import "XMLRPCConnection+Authentication.h"
#import "NSString+Util.h"
#import "NSData+Base64.h"
#import "CTidy.h"

@implementation XMLRPCConnection (Authentication)

+ (XMLRPCResponse *)sendSynchronousXMLRPCRequest:(XMLRPCRequest *)xmlRequest 
									withUsername:(NSString *)username 
									 andPassword:(NSString *)password {
	NSURLResponse *urlres;	
	NSError *err = NULL;
	NSMutableURLRequest *request = [[xmlRequest request] mutableCopy];
	
	NSString *format = [NSString stringWithFormat:@"%@:%@", username, password];
	NSData *formatData = [format dataUsingEncoding:NSASCIIStringEncoding];
	[request addValue:[NSString stringWithFormat:@"Basic %@", [formatData base64EncodedString]] forHTTPHeaderField:@"Authorization"];
	
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlres error:&err];
	
	if( err != NULL )
		return (id) err;
	
 	if (data != nil) {
		NSString  *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		if ( ! str ) {
			str = [[[NSString alloc] initWithData:data encoding:[NSString defaultCStringEncoding]] autorelease];
			data = [str dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
		}
		
		//Check for HTML code 400 or greater in response statusCode (from header) and throw error if so
		if ([urlres isKindOfClass:[NSHTTPURLResponse class]]) {
			
			if ([(NSHTTPURLResponse *) urlres statusCode] >= 400) {
				
				//	NSLog(@"Received status code: %d %@", [(NSHTTPURLResponse *) urlres statusCode], 
				//	[NSHTTPURLResponse localizedStringForStatusCode:[(NSHTTPURLResponse *) urlres statusCode]]) ;
				
				NSString *errorIntString = [NSString stringWithFormat:@"%d", [(NSHTTPURLResponse *) urlres statusCode]];
				NSString *stringForStatusCode = [NSHTTPURLResponse localizedStringForStatusCode:[(NSHTTPURLResponse *) urlres statusCode]];
				NSString *errorString = [[errorIntString stringByAppendingString:@" "] stringByAppendingString:stringForStatusCode];
				
				NSInteger code = -1; //This is not significant, just a number with no meaning
				NSDictionary *usrInfo = [NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedDescriptionKey];
				err = [NSError errorWithDomain:@"org.wordpress.iphone" code:code userInfo:usrInfo];
				return (id) err;
			}
		}
		
		//get rid of weird characters before the xml preamble
		int responseLenght = [str length];
		//NSLog (@"String length is %i", responseLenght);
		int charIndex = 0;

		for( ; charIndex < responseLenght; charIndex++) {
			unichar testChar = [str characterAtIndex:charIndex];
			if(testChar == 60) {
		//		NSLog (@"found the correct start char at index %i", charIndex);
				break;
			} else {
		//		NSLog (@"invalid response char at index %i", charIndex );
			}
		} //end for

		if(charIndex != 0) {
			str = [str substringFromIndex: charIndex];
		}

		//cleans the document
		//NSLog (@"--begin tidy process");
		NSError *theError = NULL;
		NSString *cleanedString = [[CTidy tidy] tidyString:str inputFormat:TidyFormat_XML outputFormat:TidyFormat_XML diagnostics:NULL error:&theError];

		if( theError != NULL )
		{
			//TODO: we may need to create a XMLRPCResponse with the error. and return
			return (id) theError;
		}
		//NSLog (@"cleaned response msg: %@", cleanedString);
		//NSLog (@"--end tidy process");

		data = nil;
		data = [NSData dataWithData:[cleanedString dataUsingEncoding: NSUTF8StringEncoding]];

		return [[[XMLRPCResponse alloc] initWithData: data] autorelease];
	}
	
	return nil;
}

@end
