//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPPropertyDescription.h"

@implementation MPPropertySelectorParameterDescription

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    NSParameterAssert(dictionary[@"name"] != nil);
    NSParameterAssert(dictionary[@"type"] != nil);

    self = [super init];
    if (self) {
        _name = [dictionary[@"name"] copy];
        _type = [dictionary[@"type"] copy];
    }

    return self;
}

@end

@implementation MPPropertySelectorDescription

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    NSParameterAssert(dictionary[@"selector"] != nil);
    NSParameterAssert(dictionary[@"parameters"] != nil);

    self = [super init];
    if (self) {
        _selectorName = [dictionary[@"selector"] copy];
        NSMutableArray *parameters = [[NSMutableArray alloc] initWithCapacity:[dictionary[@"parameters"] count]];
        for (NSDictionary *parameter in dictionary[@"parameters"]) {
            [parameters addObject:[[MPPropertySelectorParameterDescription alloc] initWithDictionary:parameter]];
        }

        _parameters = [parameters copy];
        _returnType = [dictionary[@"result"][@"type"] copy]; // optional
    }

    return self;
}

@end

@interface MPPropertyDescription ()

@property (nonatomic, readonly) NSPredicate *predicate;

@end

@implementation MPPropertyDescription

+ (NSValueTransformer *)valueTransformerForType:(NSString *)typeName
{
    // TODO: lookup transformer by type

    for (NSString *toTypeName in @[@"NSDictionary", @"NSNumber", @"NSString"]) {
        NSString *toTransformerName = [NSString stringWithFormat:@"MP%@To%@ValueTransformer", typeName, toTypeName];
        NSValueTransformer *toTransformer = [NSValueTransformer valueTransformerForName:toTransformerName];
        if (toTransformer) {
            return toTransformer;
        }
    }

    // Default to pass-through.
    return [NSValueTransformer valueTransformerForName:@"MPPassThroughValueTransformer"];
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    NSParameterAssert(dictionary[@"name"] != nil);

    self = [super init];
    if (self) {
        _name = [dictionary[@"name"] copy]; // required
        _useInstanceVariableAccess = [dictionary[@"use_ivar"] boolValue]; // Optional
        _readonly = [dictionary[@"readonly"] boolValue]; // Optional
        _nofollow = [dictionary[@"nofollow"] boolValue]; // Optional

        NSString *predicateFormat = dictionary[@"predicate"]; // Optional
        if (predicateFormat) {
            _predicate = [NSPredicate predicateWithFormat:predicateFormat];
        }

        NSDictionary *get = dictionary[@"get"];
        if (get == nil) {
            NSParameterAssert(dictionary[@"type"] != nil);
            get = @{
                    @"selector" : _name,
                    @"result" : @{
                            @"type" : dictionary[@"type"],
                            @"name" : @"value"
                    },
                    @"parameters": @[]
            };
        }

        NSDictionary *set = dictionary[@"set"];
        if (set == nil && _readonly == NO) {
            NSParameterAssert(dictionary[@"type"] != nil);
            set = @{
                    @"selector" : [NSString stringWithFormat:@"set%@:", [_name capitalizedString]],
                    @"parameters" : @[
                            @{
                                    @"name" : @"value",
                                    @"type" : dictionary[@"type"]
                            }
                    ]
            };
        }

        _getSelectorDescription = [[MPPropertySelectorDescription alloc] initWithDictionary:get];
        if (set) {
            _setSelectorDescription = [[MPPropertySelectorDescription alloc] initWithDictionary:set];
        } else {
            _readonly = YES;
        }

        BOOL useKVC = (dictionary[@"use_kvc"] == nil ? YES : [dictionary[@"use_kvc"] boolValue]) && _useInstanceVariableAccess == NO;
        _useKeyValueCoding = useKVC &&
                [_getSelectorDescription.parameters count] == 0 &&
                (_setSelectorDescription == nil || [_setSelectorDescription.parameters count] == 1);
    }

    return self;
}

- (NSString *)type
{
    return _getSelectorDescription.returnType;
}

- (NSValueTransformer *)valueTransformer
{
    return [[self class] valueTransformerForType:self.type];
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@:%p name='%@' type='%@' %@>", NSStringFromClass([self class]), (__bridge void *)self, self.name, self.type, self.readonly ? @"readonly" : @""];
}

- (BOOL)shouldReadPropertyValueForObject:(NSObject *)object
{
    if (_nofollow) {
        return NO;
    }
    if (_predicate) {
        return [_predicate evaluateWithObject:object];
    }

    return YES;
}

@end
