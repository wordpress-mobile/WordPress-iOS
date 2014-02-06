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

+ (NSString *)sp_JSONStringFromObject:(id)object
{
    if (!object) return nil;

    NSError __autoreleasing *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object
                                                   options:SPJSONWritingOptions
                                                     error:&error];

    if (error) {
        NSLog(@"JSON Serialization of object %@ failed due to error %@",object, error);
        return nil;
    }

    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (id)sp_JSONObjectWithData:(NSData *)data
{
    if (!data) return nil;

    NSError __autoreleasing *error = nil;

    id value = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves error:&error];
    if (error) {
        NSLog(@"JSON Deserialization of data %@ failed due to error %@",data, error);
        return nil;
    }
    return value;
}


@end

@implementation NSArray (SPJSONKitAdapterCategories)

- (NSString *)sp_JSONString
{
    return [NSJSONSerialization sp_JSONStringFromObject:self];
}

@end

@implementation NSDictionary (SPJSONKitAdapterCategories)

- (NSString *)sp_JSONString
{
    return [NSJSONSerialization sp_JSONStringFromObject:self];
}

@end



@implementation NSString (SPJSONKitAdapterCategories)

- (id)sp_objectFromJSONString
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization sp_JSONObjectWithData:data];
}

@end

@implementation NSData (SPJSONKitAdapterCategories)

- (id)sp_objectFromJSONString
{
    return [NSJSONSerialization sp_JSONObjectWithData:self];
}

@end
