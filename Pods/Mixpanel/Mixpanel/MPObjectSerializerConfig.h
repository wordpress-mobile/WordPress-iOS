//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import <Foundation/Foundation.h>

@class MPEnumDescription;
@class MPClassDescription;
@class MPTypeDescription;


@interface MPObjectSerializerConfig : NSObject

@property (nonatomic, readonly) NSArray *classDescriptions;
@property (nonatomic, readonly) NSArray *enumDescriptions;

- (id)initWithDictionary:(NSDictionary *)dictionary;

- (MPTypeDescription *)typeWithName:(NSString *)name;
- (MPEnumDescription *)enumWithName:(NSString *)name;
- (MPClassDescription *)classWithName:(NSString *)name;

@end
