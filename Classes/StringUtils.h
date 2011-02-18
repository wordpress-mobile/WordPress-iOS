//
//  StringUtils.h
//  WordPress
//
//  Created by Danilo Ercoli on 18/02/11.
//  Copyright 2011 WordPress. All rights reserved.
//


@interface StringUtils : NSObject {

}

+ (NSString*) makeValidUTF8:(NSString*) stringToCheck;
+ (BOOL) isValidUTF8:(NSString*) stringToCheck;
+ (NSString*) removeInvalidCharsFromString:(NSString*) stringToCheck;

@end