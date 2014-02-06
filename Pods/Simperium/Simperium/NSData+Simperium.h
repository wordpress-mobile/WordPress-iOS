//
//  NSData+Simperium.h
//  Simperium
//
//  Created by Michael Johnston on 11-06-03.
//  Copyright 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData(NSData_Simperium)

+ (NSData *)sp_decodeBase64WithString:(NSString *)strBase64;

@end
