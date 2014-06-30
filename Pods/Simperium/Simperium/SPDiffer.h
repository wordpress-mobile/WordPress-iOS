//
//  SPDiffer.h
//
//  Created by Michael Johnston on 11-02-11.
//  Copyright 2011 Simperium. All rights reserved.
//

// You shouldn't need to call any methods or access any properties directly in this class. Feel free to browse though.

#import <Foundation/Foundation.h>
#import "SPDiffable.h"


@class SPMember;
@class SPGhost;
@class SPSchema;

#pragma mark ====================================================================================
#pragma mark SPDiffer
#pragma mark ====================================================================================

@interface SPDiffer : NSObject

@property (nonatomic, strong) SPSchema *schema;

- (id)initWithSchema:(SPSchema *)schema;
- (NSMutableDictionary *)diffForAddition:(id<SPDiffable>)object;
- (NSDictionary *)diffFromDictionary:(NSDictionary *)dict toObject:(id<SPDiffable>)object;
- (BOOL)applyDiffFromDictionary:(NSDictionary *)diff toObject:(id<SPDiffable>)object error:(NSError **)error;
- (BOOL)applyGhostDiffFromDictionary:(NSDictionary *)diff toObject:(id<SPDiffable>)object error:(NSError **)error;
- (NSDictionary *)transform:(id<SPDiffable>)object diff:(NSDictionary *)diff oldDiff:(NSDictionary *)oldDiff oldGhost:(SPGhost *)oldGhost error:(NSError **)error;

@end
