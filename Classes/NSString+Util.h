//
//  NSString+Util.h
//  WordPress
//
//  Created by Josh Bassett on 18/06/09.
//

#import <Foundation/Foundation.h>


@interface NSString (Util)

- (bool)isEmpty;
- (NSString *)trim;
- (NSNumber *)numericValue;

@end

@interface NSObject (NumericValueHack)
- (NSNumber *)numericValue;
@end