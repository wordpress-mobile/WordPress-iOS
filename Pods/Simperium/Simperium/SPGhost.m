//
//  SPGhost.m
//  Simperium
//
//  Created by Michael Johnston on 11-03-08.
//  Copyright 2011 Simperium. All rights reserved.
//

#import "SPGhost.h"


@implementation SPGhost

- (id)initFromDictionary:(NSDictionary *)dict {
    if ((self = [super init])) {
        _key        = dict[@"key"];
        _memberData = dict[@"obj"];
        _version    = dict[@"version"];
        
        // Make sure it's not marked dirty when initializing in this way, since ghosts are loaded
        // through this method on launch
        _needsSave = NO;
    }
    
	return self;
}

- (id)initWithKey:(NSString *)k memberData:(NSMutableDictionary *)data {
	if ((self = [super init])) {
		_key        = k;
		_memberData = data;
	}
	return self;
}

- (id)copyWithZone: (NSZone *) zone {
    SPGhost *newGhost = [[[self class] allocWithZone:zone] init];
	newGhost.key = [self key];
	newGhost.memberData = [self memberData];
    newGhost.version = [self version];
    return newGhost;
}

- (id)mutableCopyWithZone: (NSZone *) zone {
    SPGhost *newGhost = [[[self class] allocWithZone:zone] init];	
	newGhost.key = [self key];
    newGhost.version = [self version];
	
	NSMutableDictionary *memberDataCopy = [[self memberData] mutableCopyWithZone:zone];
	newGhost.memberData = memberDataCopy;
	return newGhost;
}

- (void)setMemberData:(NSMutableDictionary *)newMemberData {
    _memberData = [newMemberData mutableCopy];
    _needsSave = YES;
}

- (void)setKey:(NSString *)newKey {
    _key = [newKey copy];
    _needsSave = YES;
}

- (void)setVersion:(NSString *)newVersion {
    _version = [newVersion copy];
    _needsSave = YES;
}

- (NSDictionary *)dictionary {
	if (_version == nil) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				self.key, @"key", self.memberData, @"obj", nil];
    } else {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				self.key, @"key", self.version, @"version", self.memberData, @"obj", nil];
    }
}

@end
