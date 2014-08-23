//
//  SPMember.m
//  Simperium
//
//  Created by Michael Johnston on 11-02-12.
//  Copyright 2011 Simperium. All rights reserved.
//

#import "Simperium.h"
#import "SPMember.h"
#import "JSONKit+Simperium.h"

@implementation SPMember
@synthesize keyName;
@synthesize valueTransformerName;
@synthesize modelDefaultValue;

// Operations used for diff and transform
NSString * const OP_OP				= @"o";
NSString * const OP_VALUE			= @"v";
NSString * const OP_REPLACE			= @"r";
NSString * const OP_LIST_INSERT		= @"+";
NSString * const OP_LIST_DELETE		= @"-";
NSString * const OP_OBJECT_ADD		= @"+";
NSString * const OP_OBJECT_REMOVE	= @"-";
NSString * const OP_OBJECT_REPLACE  = @"r";
NSString * const OP_INTEGER			= @"I";
NSString * const OP_LIST			= @"L";
NSString * const OP_LIST_DMP		= @"dL";
NSString * const OP_OBJECT			= @"O";
NSString * const OP_STRING			= @"d";

- (id)initFromDictionary:(NSDictionary *)dict
{
	if ((self = [self init])) {			
		keyName = [[dict objectForKey:@"name"] copy];
		type = [[dict objectForKey:@"type"] copy];
        valueTransformerName = [[dict objectForKey:@"valueTransformerName"] copy];
        modelDefaultValue = [[dict objectForKey:@"defaultValue"] copy];
	}
	
	return self;	
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ of type %@", keyName, type];
}

- (NSDictionary *)diffForAddition:(id)data {
    NSMutableDictionary *diff = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 OP_OBJECT_ADD, OP_OP,
                                 nil];    
    
    [self setValue:data forKey:OP_VALUE inDictionary:diff];
    return diff;
}

- (NSDictionary *)diffForReplacement:(id)data {
    NSMutableDictionary *diff = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 OP_REPLACE, OP_OP,
                                 nil];
    
    [self setValue:data forKey:OP_VALUE inDictionary:diff];
    return diff;
}


- (NSDictionary *)diffForRemoval {
    NSMutableDictionary *diff = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 OP_OBJECT_REMOVE, OP_OP,
                                 nil];    

    return diff;
}

- (id)defaultValue {
	return nil;
}

- (id)getValueFromDictionary:(NSDictionary *)dict key:(NSString *)key object:(id<SPDiffable>)object {
    id value = [dict objectForKey: key];
    return value;
}

- (void)setValue:(id)value forKey:(NSString *)key inDictionary:(NSMutableDictionary *)dict {
    [dict setValue:value forKey:key];
}

- (NSDictionary *)diff:(id)thisValue otherValue:(id)otherValue {
	return nil;
}

- (id)applyDiff:(id)thisValue otherValue:(id)otherValue error:(NSError **)error {
	return otherValue;
}


- (NSDictionary *)transform:(id)thisValue otherValue:(id)otherValue oldValue:(id)oldValue error:(NSError **)error {
	// By default, don't perform any transformation
	return nil;
}

@end


/* Could make SPEntity itself a supported member class, and perform diff this way:
 
- (NSDictionary *)diff: (SPEntity *)otherEntity
{
	// changes contains the operations for every key that is different
	NSMutableDictionary *changes = [NSMutableDictionary dictionary];
	
	if (![self isKindOfClass:[otherEntity class]])
	{
		NSLog(@"Simperium warning: tried to diff two entities of different types");
		return changes;
	}
	
	// We cycle through all members of this entity and check their vaules against otherEntity
	// In the JS version, members can be added/removed this way too (if a member is present in one entity
	// but not the other); ignore this functionality for now
	NSAssert([[[self class] members] count] == [[[otherEntity class] members] count],
			 @"Simperium error: entity member lists didn't match during a diff");
	NSDictionary *currentDiff = [NSDictionary dictionary];
	for (int i=0; i<[members count]; i++)
	{
		SPMember *thisMember = [members objectAtIndex: i];
		SPMember *otherMember = [[[otherEntity class] members] objectAtIndex: i];
		id thisValue = [self valueForKey:[thisMember keyName]];
		id otherValue = [self valueForKey:[otherMember keyName]];
		
		// Perform the actual diff; the mechanics of the diff will depend on the member class
		currentDiff = [thisMember diff: thisValue otherValue:otherValue];
		
		// If there was no difference, then don't add any changes for this member
		if (currentDiff == nil || [currentDiff count] == 0)
			continue;
		
		// Otherwise, add this as a change
		[changes setObject:currentDiff forKey:[thisMember keyName]];
	}
	
	return changes;
}
*/

