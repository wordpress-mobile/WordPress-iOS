//
//  XMLRPCConnection+Authentication.m
//  WordPress
//
//  Created by Jeff Stieler on 11/17/09.
//

#import "XMLRPCConnection+Authentication.h"
#import "NSString+Util.h"
#import "NSData+Base64.h"

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
		NSString  *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		if ( ! str ) {
			str = [[NSString alloc] initWithData:data encoding:[NSString defaultCStringEncoding]];
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
		
		return [[[XMLRPCResponse alloc] initWithData: data] autorelease];
	}
	
	return nil;
}

@end
