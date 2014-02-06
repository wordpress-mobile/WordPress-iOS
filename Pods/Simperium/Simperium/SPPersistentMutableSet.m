//
//  SPPersistentMutableSet.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 1/14/14.
//  Copyright (c) 2014 Simperium. All rights reserved.
//

#import "SPPersistentMutableSet.h"
#import "JSONKit+Simperium.h"



#pragma mark ====================================================================================
#pragma mark Private Methods
#pragma mark ====================================================================================

@interface SPPersistentMutableSet ()
@property (nonatomic, strong, readwrite) NSString		*label;
@property (nonatomic, strong, readwrite) NSMutableSet	*contents;
@end


#pragma mark ====================================================================================
#pragma mark SPMutableSetStorage
#pragma mark ====================================================================================

@implementation SPPersistentMutableSet

- (id)initWithLabel:(NSString *)label {
	if ((self = [super init])) {
		self.label		= label;
		self.contents	= [NSMutableSet setWithCapacity:3];
	}
	
	return self;
}

- (void)addObject:(id)object {
	[self.contents addObject:object];
}

- (void)removeObject:(id)object {
	[self.contents removeObject:object];
}

- (NSArray *)allObjects {
	return self.contents.allObjects;
}

- (NSUInteger)count {
	return self.contents.count;
}

- (void)addObjectsFromArray:(NSArray *)array {
	[self.contents addObjectsFromArray:array];
}

- (void)minusSet:(NSSet *)otherSet {
	[self.contents minusSet:otherSet];
}

- (void)removeAllObjects {
	return [self.contents removeAllObjects];
}


#pragma mark ====================================================================================
#pragma mark NSFastEnumeration
#pragma mark ====================================================================================

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len {
	return [self.contents countByEnumeratingWithState:state objects:buffer count:len];
}


#pragma mark ====================================================================================
#pragma mark Persistance!
#pragma mark ====================================================================================

- (void)save {
    NSString *json = [[self.contents allObjects] sp_JSONString];
	[[NSUserDefaults standardUserDefaults] setObject:json forKey:self.label];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (instancetype)loadSetWithLabel:(NSString *)label {
	SPPersistentMutableSet *loaded = [[SPPersistentMutableSet alloc] initWithLabel:label];
	NSArray *list = [[[NSUserDefaults standardUserDefaults] objectForKey:label] sp_objectFromJSONString];
	
    if (list.count > 0) {
        [loaded addObjectsFromArray:list];
	}
	
	return loaded;
}


@end
