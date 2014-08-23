//
//  SPSchema.m
//  Simperium
//
//  Created by Michael Johnston on 11-05-16.
//  Copyright 2011 Simperium. All rights reserved.
//

#import "Simperium.h"
#import "SPSchema.h"
#import "SPMember.h"
#import "SPMemberText.h"
#import "SPMemberDate.h"
#import "SPMemberInt.h"
#import "SPMemberFloat.h"
#import "SPMemberDouble.h"
#import "SPMemberEntity.h"
#import "SPMemberJSON.h"
#import "SPMemberJSONList.h"
#import "SPMemberList.h"
#import "SPMemberBase64.h"

@interface SPSchema ()
@property (nonatomic, strong) NSDictionary *memberMap;
@end


@implementation SPSchema

- (NSDictionary *)memberMap {
	if (_memberMap) {
		return _memberMap;
	}
	
	_memberMap = @{
		@"text"		: NSStringFromClass([SPMemberText class]),
		@"int"		: NSStringFromClass([SPMemberInt class]),
		@"bool"		: NSStringFromClass([SPMemberInt class]),
		@"date"		: NSStringFromClass([SPMemberDate class]),
		@"entity"	: NSStringFromClass([SPMemberEntity class]),
		@"double"	: NSStringFromClass([SPMemberDouble class]),
		@"list"		: NSStringFromClass([SPMemberList class]),
		@"json"		: NSStringFromClass([SPMemberJSON class]),
		@"jsonlist" : NSStringFromClass([SPMemberJSONList class]),
		@"base64"	: NSStringFromClass([SPMemberBase64 class])
	};
	
	return _memberMap;
}

- (Class)memberClassForType:(NSString *)type {
		
	NSString *name = self.memberMap[type];
	return name ? NSClassFromString(name) : nil;
}

// Loads an entity's definition (name, members, their types, etc.) from a plist dictionary
- (id)initWithBucketName:(NSString *)name data:(NSDictionary *)definition {
    if (self = [super init]) {
        _bucketName = [name copy];
        NSArray *memberList = [definition valueForKey:@"members"];
        _members = [NSMutableDictionary dictionaryWithCapacity:3];
        _binaryMembers = [NSMutableArray arrayWithCapacity:3];
		
        for (NSDictionary *memberDict in memberList) {
            NSString *typeStr = [memberDict valueForKey:@"type"];
            SPMember *member = [[[self memberClassForType:typeStr] alloc] initFromDictionary:memberDict];
			
			if (member) {
				[self.members setObject:member forKey:member.keyName];
			}
        }        
    }
    
    return self;
}

- (void)addMemberForObject:(id)object key:(NSString *)key {
    if (!_dynamic) {
        return;
	}
    
    if ([self memberForKey:key]) {
        return;
	}
    
    NSString *type = @"unsupported";
    if ([object isKindOfClass:[NSString class]]) {
        type = @"text";
	} else if ([object isKindOfClass:[NSNumber class]]) {
        type = @"double";
	}
    
    NSDictionary *memberDict = @{ @"type" : type,
								  @"name" : key };
    SPMember *member = [[[self memberClassForType:type] alloc] initFromDictionary:memberDict];
	if (member) {
		[self.members setObject:member forKey:member.keyName];
	}
    
}

- (SPMember *)memberForKey:(NSString *)memberName {
    return _members[memberName];
}

- (void)setDefaults:(id<SPDiffable>)object {
    // Set default values for all members that don't already have them
    // This now gets called after some data might already have been set, so be careful
    // not to overwrite it
    for (SPMember *member in [self.members allValues]) {
        if (member.modelDefaultValue == nil && [object simperiumValueForKey:member.keyName] == nil)
            [object simperiumSetValue:[member defaultValue] forKey:member.keyName];
    }
}

@end
