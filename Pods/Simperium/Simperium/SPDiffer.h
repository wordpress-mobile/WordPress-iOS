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

@interface SPDiffer : NSObject {
    SPSchema *schema;
}

@property (nonatomic, strong) SPSchema *schema;

- (id)initWithSchema:(SPSchema *)schema;
- (NSMutableDictionary *)diffForAddition: (id<SPDiffable>)object;
- (NSDictionary *)diff:(id<SPDiffable>)object withDictionary:(NSDictionary *)dict;
- (void)applyDiff:(NSDictionary *)diff to:(id<SPDiffable>)object;
- (void)applyGhostDiff:(NSDictionary *)diff to:(id<SPDiffable>)object;
- (NSDictionary *)transform:(id<SPDiffable>)object diff:(NSDictionary *)diff oldDiff:(NSDictionary *)oldDiff oldGhost:(SPGhost *)oldGhost;

@end
