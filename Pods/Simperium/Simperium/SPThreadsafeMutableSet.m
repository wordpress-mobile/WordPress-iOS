//
//  SPThreadsafeMutableSet.m
//  Simperium
//
//  Created by Jorge Leandro Perez on 11/26/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "SPThreadsafeMutableSet.h"



#pragma mark ====================================================================================
#pragma mark Private
#pragma mark ====================================================================================

@interface SPThreadsafeMutableSet ()
@property (nonatomic, strong) NSMutableSet		*contents;
@property (nonatomic, strong) dispatch_queue_t	queue;
@end


#pragma mark ====================================================================================
#pragma mark SPThreadsafeMutableSet
#pragma mark ====================================================================================

@implementation SPThreadsafeMutableSet

- (id)init {
	if ((self = [super init])) {
		self.contents = [NSMutableSet set];
        self.queue = dispatch_queue_create("com.simperium.SPThreadsafeMutableSet", NULL);
	}
	
	return self;
}

- (NSArray *)allObjects {
	__block NSArray* allObjects = nil;
	dispatch_sync(self.queue, ^{
		allObjects = self.contents.allObjects;
	});
	return allObjects;
}

- (BOOL)containsObject:(id)anObject {
	__block BOOL contains = NO;
	dispatch_sync(self.queue, ^{
		contains = [self.contents containsObject:anObject];
	});
	return contains;
}

- (NSUInteger)count {
	__block NSUInteger count = 0;
	dispatch_sync(self.queue, ^{
		count = self.contents.count;
	});
	return count;
}

- (void)addObject:(id)object {
	dispatch_async(self.queue, ^{
		[self.contents addObject:object];
	});
}

- (void)removeObject:(id)object {
	dispatch_async(self.queue, ^{
		[self.contents removeObject:object];
	});
}

+ (instancetype)set {
	return [[[self class] alloc] init];
}

@end
