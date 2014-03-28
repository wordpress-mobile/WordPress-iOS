//
//  SPMemberJSON.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 02-18-2014.
//  Copyright (c) 2014 Simperium. All rights reserved.
//

#import "SPMemberJSON.h"
#import "NSData+Simperium.h"
#import "NSString+Simperium.h"
#import "JSONKit+Simperium.h"


/**
	Support for JSON entities stored in CoreData fields. In order to map this helper, you'll need to:
	-	Toggle your CoreData attribute as Transformable
	-	Set the attribute 'spOverride = json' in the Transformable's UserInfo.
 */
@implementation SPMemberJSON

- (id)defaultValue {
	return nil;
}

- (NSString *)stringValueFromTransformable:(id)value {
    if (value == nil) {
        return @"";
	}
    
    // Convert from a Transformable class to a base64 string
    NSData *data = nil;
					
	if (self.valueTransformerName) {
		data = [[NSValueTransformer valueTransformerForName:self.valueTransformerName] transformedValue:value];
	} else {
		data = [NSKeyedArchiver archivedDataWithRootObject:value];
	}
    
	return [NSString sp_encodeBase64WithData:data];
}


- (id)getValueFromDictionary:(NSDictionary *)dict key:(NSString *)key object:(id<SPDiffable>)object {
    id value = dict[key];
	
	// When the value is a string it means that it's been archived. Otherwise return the object
	if (![value isKindOfClass:[NSString class]]) {
		return value;
	}
    
	// Convert from NSString (base64) to NSData
    NSData *data  = [NSData sp_decodeBase64WithString:value];
    id unarchived = nil;

	if (self.valueTransformerName) {
		unarchived = [[NSValueTransformer valueTransformerForName:self.valueTransformerName] reverseTransformedValue:data];
	} else {
		unarchived = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	}
	
    // A nil value will be encoded as an empty string, so check for that
	if ([unarchived isKindOfClass:[NSString class]] && [unarchived length] == 0) {
		return nil;
	}
	
	return unarchived;
}

- (void)setValue:(id)value forKey:(NSString *)key inDictionary:(NSMutableDictionary *)dict {
	// Let's archive objects before they can be safely stored in CoreData
    dict[key] = [self stringValueFromTransformable:value];
}

- (NSDictionary *)diff:(id)thisValue otherValue:(id)otherValue {
    
    if ([thisValue isEqual: otherValue]) {
        return @{ };
    }
	
    NSString *thisStr  = [self stringValueFromTransformable:thisValue];
    NSString *otherStr = [self stringValueFromTransformable:otherValue];
    if ([thisStr compare:otherStr] == NSOrderedSame) {
        return @{ };
	}
    
	// Construct the diff in the expected format
	return @{
		OP_OP		: OP_REPLACE,
		OP_VALUE	: [self stringValueFromTransformable: otherValue]
	};
}

- (id)applyDiff:(id)thisValue otherValue:(id)otherValue {
	
	// Dictionary: Handle +, -, r, O
	if ([thisValue isKindOfClass:[NSDictionary class]] && [otherValue isKindOfClass:[NSDictionary class]]) {
		return [self applyDiff:otherValue onDictionary:thisValue];
	}
	
	return otherValue;
}

- (id)applyDiff:(NSDictionary *)diffDict onDictionary:(NSDictionary *)thisDict {
	
	NSMutableDictionary *updatedDict = [thisDict mutableCopy];
	
	for (NSString *key in diffDict.allKeys) {
		NSDictionary *payload = diffDict[key];
		id value = payload[OP_VALUE];
		
		// Operation: Replace / Insert
		if ([payload[OP_OP] isEqualToString:OP_REPLACE] || [payload[OP_OP] isEqualToString:OP_LIST_INSERT]) {
			
			if (value) {
				updatedDict[key] = value;
			}
			
		// Operation: Delete
		} else if([payload[OP_OP] isEqualToString:OP_LIST_DELETE]) {
			[updatedDict removeObjectForKey:key];
			
		// Operation: Object
		} else if([payload[OP_OP] isEqualToString:OP_OBJECT]) {
			
			NSDictionary *target = updatedDict[key];
			if ([value isKindOfClass:[NSDictionary class]] && [target isKindOfClass:[NSDictionary class]]) {
				id result = [self applyDiff:value onDictionary:target];
				if (result) {
					updatedDict[key] = result;
				}
			}
		}
	}
		
	return updatedDict;
}

@end
