//
//  SPManagedObject.h
//
//  Created by Michael Johnston on 11-02-11.
//  Copyright 2011 Simperium. All rights reserved.
//

// You shouldn't need to call any methods or access any properties directly in this class. Feel free to browse though.

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SPDiffable.h"

@class SPMember;
@class SPGhost;
@class SPBucket;

@interface SPManagedObject : NSManagedObject <SPDiffable> {
	// The entity's member data as last seen by the server, stored in dictionary form for diffing
	// has key, data, and signature
	SPGhost *ghost;
    SPBucket *__weak bucket;
    
    NSString *simperiumKey;
    NSString *ghostData;
	
	// Flagged if changed while waiting for server ack (could be tracked externally instead)
	BOOL updateWaiting;
}

@property (strong, nonatomic) SPGhost *ghost;
@property (weak, nonatomic) SPBucket *bucket;
@property (copy, nonatomic) NSString *ghostData;
@property (copy, nonatomic) NSString *simperiumKey;
@property (nonatomic) BOOL updateWaiting;

- (void)loadMemberData:(NSDictionary *)dictionary;
- (NSDictionary *)dictionary;
- (NSString *)version;


// Note: The following methods are meant to be overriden, if needed.
// Selector 'awakeFromRemoteInsert' will get called just once, right after a remote insertion is performed.
// From then on, 'awakeFromLocalInsert' will be called each time the object is inserted in a NSManagedObjectContext.
- (void)awakeFromLocalInsert;
- (void)awakeFromRemoteInsert;

@end
