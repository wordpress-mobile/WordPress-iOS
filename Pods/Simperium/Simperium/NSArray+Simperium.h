//
//  NSArray+Simperium.h
//  Simperium
//
//  Created by Andrew Mackenzie-Ross on 19/07/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DiffMatchPatch;

@interface NSArray (Simperium)

// DiffMatchPatch Array Operations

// Create a diff from the receiver using diff match patch.
- (NSString *)sp_diffDeltaWithArray:(NSArray *)obj diffMatchPatch:(DiffMatchPatch *)dmp;

// Returns the result of applying a diff to the receiver using diff match patch.
- (NSArray *)sp_arrayByApplyingDiffDelta:(NSString *)delta diffMatchPatch:(DiffMatchPatch *)dmp;

// Returns a transformed diff on top of another diff using diff match patch.
- (NSString *)sp_transformDelta:(NSString *)delta onto:(NSString *)otherDelta diffMatchPatch:(DiffMatchPatch *)dmp;

// TODO: Implement OP_LIST methods
// Create a diff from the receiver
//- (NSDictionary *)sp_diffWithArray:(NSArray *)obj;
// Returns the result of applying a diff to the receiver using diff match patch.
//- (NSArray *)sp_applyDiff:(NSDictionary *)diff;
// Returns a transformed diff on top of another diff using diff match patch.
//- (NSDictionary *)sp_transformDiff:(NSDictionary *)diff onto:(NSDictionary *)otherDiff;

@end
