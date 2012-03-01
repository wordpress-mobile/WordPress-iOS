//
//  NSMutableDictionary+Helpers.h
//  WordPress
//
//  Created by Jorge Bernal on 2/29/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (Helpers)
- (void)setValueIfNotNil:(id)value forKey:(NSString *)key;
@end
