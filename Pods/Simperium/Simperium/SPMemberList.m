//
//  SPMemberList.m
//  Simperium
//
//  Created by Michael Johnston on 11-11-24.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import "SPMemberList.h"
#import "JSONKit+Simperium.h"
#import "DiffMatchPatch.h"
#import "NSArray+Simperium.h"

@interface SPMemberList ()
@property (nonatomic, strong, readonly) DiffMatchPatch *diffMatchPatch;
@end

@implementation SPMemberList
@synthesize diffMatchPatch = _diffMatchPatch;

- (DiffMatchPatch *)diffMatchPatch
{
	if (!_diffMatchPatch) {
		_diffMatchPatch = [[DiffMatchPatch alloc] init];
	}
	return _diffMatchPatch;
}

- (id)defaultValue {
	return @"[]";
}

- (id)arrayFromJSONString:(id)value {
    if ([value length] == 0)
        return [[self defaultValue] sp_objectFromJSONString];
	return [value sp_objectFromJSONString];
}

- (id)getValueFromDictionary:(NSDictionary *)dict key:(NSString *)key object:(id<SPDiffable>)object {
	return [self getValueFromJSON:dict key:key object:object];
}

- (id)getValueFromJSON:(NSDictionary *)json key:(NSString *)key object:(id<SPDiffable>)object
{
	id value = [json objectForKey:key];
	return [value sp_JSONString];
}

- (void)setValue:(id)value forKey:(NSString *)key inDictionary:(NSMutableDictionary *)dict {
    id convertedValue = [self arrayFromJSONString: value];
    [dict setValue:convertedValue forKey:key];
}

- (NSDictionary *)diff:(NSArray *)a otherValue:(NSArray *)b {
	NSAssert([a isKindOfClass:[NSArray class]] && [b isKindOfClass:[NSArray class]],
			 @"Simperium error: couldn't diff list because their classes weren't NSArray");
    
    if ([a isEqualToArray:b])
		return [NSDictionary dictionary];
	
	// For the moment we can only create OP_LIST_DMP
	return @{ OP_OP: OP_LIST_DMP, OP_VALUE: [a sp_diffDeltaWithArray:b diffMatchPatch:self.diffMatchPatch] };
}

- (id)applyDiff:(id)thisValue otherValue:(id)otherValue error:(NSError **)error {
	
	// Assuming OP_LIST_DMP. This code will have to change when OP_LIST is
	// implemented and it will have to take the full change diff in order
	// to apply the right diffing method.
	NSString *delta = otherValue;
	NSArray *source = thisValue;
	
	return [source sp_arrayByApplyingDiffDelta:delta diffMatchPatch:self.diffMatchPatch];
}

- (NSDictionary *)transform:(id)thisValue otherValue:(id)otherValue oldValue:(id)oldValue error:(NSError **)error {
	NSArray *source = oldValue;
	NSString *delta1 = thisValue;
	NSString *delta2 = otherValue;
	
	return @{ OP_OP: OP_LIST_DMP, OP_VALUE: [source sp_transformDelta:delta1 onto:delta2 diffMatchPatch:self.diffMatchPatch] };
}

@end



