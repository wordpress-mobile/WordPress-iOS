//
//  RegExProcessor.h
//  WordPress
//
//  Created by John Bickerstaff on 7/11/09.
//  
//

#import <Foundation/Foundation.h>
#import "RegexKitLite.h"

@interface RegExProcessor : NSObject {

}

- (NSString *) lookForXMLRPCEndpointInURLString:(NSString *) urlString;

@end
