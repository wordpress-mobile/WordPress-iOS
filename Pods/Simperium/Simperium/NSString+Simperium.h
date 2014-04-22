//
//  NSString+Simperium.h
//  Simperium
//
//  Created by Michael Johnston on 11-06-03.
//  Copyright 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString(NSString_Simperium)

+ (NSString *)sp_encodeBase64WithString:(NSString *)strData;
+ (NSString *)sp_encodeBase64WithData:(NSData *)objData;
+ (NSString *)sp_makeUUID;
+ (NSString *)sp_md5StringFromData:(NSData *)data;
- (NSString *)sp_urlEncodeString;
- (NSArray *)sp_componentsSeparatedByString:(NSString *)separator limit:(NSInteger)limit;

@end
