//
//  JSONKit+Simperium.h
//  Simperium
//
//  Created by Andrew Mackenzie-Ross on 9/10/2013.
//  Copyright (c) 2013 Simperium. All rights reserved.
//


// Adapters to NSJSONSerializer using the JSONKit interface
@interface NSArray (SPJSONKitAdapterCategories)
- (NSData *)sp_JSONData;
- (NSString *)sp_JSONString;
- (NSString *)sp_JSONStringWithError:(NSError **)error;
@end

@interface NSDictionary (SPJSONKitAdapterCategories)
- (NSString *)sp_JSONString;
- (NSString *)sp_JSONStringWithError:(NSError **)error;
@end

@interface NSString (SPJSONKitAdapterCategories)
- (id)sp_objectFromJSONString;
- (id)sp_objectFromJSONStringWithError:(NSError**)error;
@end

@interface NSData (SPJSONKitAdapterCategories)
- (id)sp_objectFromJSONString;
- (id)sp_objectFromJSONStringWithError:(NSError **)error;
@end
