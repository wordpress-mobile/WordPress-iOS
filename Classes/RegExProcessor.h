//
//  RegExProcessor.h
//  WordPress
//
//  Created by John Bickerstaff on 7/11/09.
//  Copyright 2009 Smilodon Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RegexKitLite.h"

@interface RegExProcessor : NSObject {

}

- (NSString *) lookForXMLRPCEndpointInURLString:(NSString *) urlString;

@end
