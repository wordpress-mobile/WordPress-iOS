//
//  WPRSDParser.h
//  WordPress
//
//  Created by Jorge Bernal on 10/18/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WPRSDParser : NSObject<NSXMLParserDelegate>
- (id)initWithXmlString:(NSString *)string;
- (NSString *)parsedEndpointWithError:(NSError **)error;
@end
