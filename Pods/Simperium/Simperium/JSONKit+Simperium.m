//
//  JSONKit+Simperium.m
//  Simperium
//
//  Created by Andrew Mackenzie-Ross on 9/10/2013.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "JSONKit+Simperium.h"

#ifdef DEBUG
static NSJSONWritingOptions const SPJSONWritingOptions = NSJSONWritingPrettyPrinted;
#else
static NSJSONWritingOptions const SPJSONWritingOptions = 0;
#endif

@implementation NSJSONSerialization (SPJSONKitAdapterCategories)

+ (NSData *)sp_JSONDataFromObject:(id)object error:(NSError **)error
{
    if (!object) {
		return nil;
	}
	
	NSError *theError = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:SPJSONWritingOptions error:&theError];
	
    if (theError) {
		if(error) {
			*error = theError;
		} else {
			NSLog(@"JSON Serialization of object %@ failed due to error %@",object, theError);
		}
		
        return nil;
    }
	
    return data;
}

+ (NSString *)sp_JSONStringFromObject:(id)object error:(NSError **)error
{
    NSData *data = [NSJSONSerialization sp_JSONDataFromObject:object error:error];
    return data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
}

+ (id)sp_JSONObjectWithData:(NSData *)data error:(NSError **)error
{
    if (!data) {
		return nil;
	}

	NSError *theError = nil;
    id value = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:&theError];
    if (theError) {
		if(error) {
			*error = theError;
		} else {
			NSLog(@"JSON Deserialization of data %@ failed due to error %@", data, theError);
		}
		
        return nil;
    }
    return value;
}


@end

@implementation NSArray (SPJSONKitAdapterCategories)

- (NSData *)sp_JSONData
{
    return [NSJSONSerialization sp_JSONDataFromObject:self error:nil];
}

- (NSString *)sp_JSONString
{
    return [NSJSONSerialization sp_JSONStringFromObject:self error:nil];
}

- (NSString *)sp_JSONStringWithError:(NSError **)error
{
    return [NSJSONSerialization sp_JSONStringFromObject:self error:error];
}

@end

@implementation NSDictionary (SPJSONKitAdapterCategories)

- (NSString *)sp_JSONString
{
    return [NSJSONSerialization sp_JSONStringFromObject:self error:nil];
}

- (NSString *)sp_JSONStringWithError:(NSError **)error
{
    return [NSJSONSerialization sp_JSONStringFromObject:self error:error];
}

@end



@implementation NSString (SPJSONKitAdapterCategories)

- (id)sp_objectFromJSONString
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
	return [NSJSONSerialization sp_JSONObjectWithData:data error:nil];
}

- (id)sp_objectFromJSONStringWithError:(NSError**)error
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
	return [NSJSONSerialization sp_JSONObjectWithData:data error:error];
}

@end

@implementation NSData (SPJSONKitAdapterCategories)

- (id)sp_objectFromJSONString
{
	return [NSJSONSerialization sp_JSONObjectWithData:self error:nil];
}

- (id)sp_objectFromJSONStringWithError:(NSError **)error
{
	return [NSJSONSerialization sp_JSONObjectWithData:self error:error];
}

@end
