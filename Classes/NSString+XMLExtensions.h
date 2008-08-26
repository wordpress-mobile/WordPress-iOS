//
//  NSString+XMLExtensions.h
//  WordPress
//
//  Created by Janakiram on 26/08/08.
//  Copyright 2008 Effigent. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NSString(XMLExtensions) 

+ (NSString *)encodeXMLCharactersIn:(NSString *)source;
+ (NSString *) decodeXMLCharactersIn:(NSString *)source;

@end
