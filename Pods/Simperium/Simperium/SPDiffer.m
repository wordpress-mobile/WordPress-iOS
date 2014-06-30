//
//  SPDiffer.m
//
//  Created by Michael Johnston on 11-02-11.
//  Copyright 2011 Simperium. All rights reserved.
//

#import "SPDiffer.h"
#import "SPMember.h"
#import "Simperium.h"
#import "SPGhost.h"
#import "JSONKit+Simperium.h"
#import "SPLogger.h"
#import "SPDiffable.h"
#import "SPSchema.h"



#pragma mark ====================================================================================
#pragma mark Constants
#pragma mark ====================================================================================

static SPLogLevels logLevel = SPLogLevelsInfo;


#pragma mark ====================================================================================
#pragma mark SPDiffer
#pragma mark ====================================================================================

@implementation SPDiffer

- (id)initWithSchema:(SPSchema *)aSchema {
    if ((self = [super init])) {
        self.schema = aSchema;
    }
    
    return self;
}


// Construct a diff for newly added entities
- (NSMutableDictionary *)diffForAddition:(id<SPDiffable>)object {
    NSMutableDictionary *diff = [NSMutableDictionary dictionaryWithCapacity: [self.schema.members count]];
    
    for (SPMember *member in [self.schema.members allValues]) {
        NSString *key = [member keyName];
		id data = [object simperiumValueForKey: key];
        
        if (data != nil) {
            NSDictionary *addDict = [member diffForAddition:data];
            [diff setObject:addDict forKey:key];
        }
	}
    return diff;
}

//  Calculates the diff required to go from Dictionary-state into Object-state
- (NSDictionary *)diffFromDictionary:(NSDictionary *)dict toObject:(id<SPDiffable>)object {
	// changes contains the operations for every key that is different
	NSMutableDictionary *changes = [NSMutableDictionary dictionaryWithCapacity:3];
	
	// We cycle through all members of the ghost and check their values against the entity
	// In the JS version, members can be added/removed this way too if a member is present in one entity
	// but not the other; ignore this functionality for now
	
	NSDictionary *currentDiff = nil;
	for (SPMember *member in [self.schema.members allValues])
    {
        NSString *key = [member keyName];
		// Make sure the member exists and is tracked by Simperium
		SPMember *thisMember = [self.schema memberForKey:key];
		if (!thisMember) {
			SPLogWarn(@"Simperium warning: trying to diff a member that doesn't exist (%@) from ghost: %@", key, [dict description]);
			continue;
		}
		
		id currentValue = [object simperiumValueForKey:key];
		id dictValue    = [thisMember getValueFromDictionary:dict key:key object:object];
        
        // If both are nil, don't add any changes
        if (!currentValue && !dictValue) {
            continue;
        }
		
		// Perform the actual diff; the mechanics of the diff will depend on the member class
        
        // If there was no previous value, then add the new value
        if (!dictValue) {
            currentDiff = [thisMember diffForAddition:currentValue];
        } else if (!currentValue && dictValue) {
            // This could happen if you have an optional member that gets set to nil
            //SPLogWarn(@"Simperium warning: trying to set a nil member (%@)", key);
            // TODO: Consider returning a diff that sets the value to [member defaultValue]
            currentDiff = [thisMember diffForRemoval];
        } else {
            // Perform a full diff
            currentDiff = [thisMember diff: dictValue otherValue:currentValue];
        }
		
		// If there was no difference, then don't add any changes for this member
		if (currentDiff == nil || [currentDiff count] == 0) {
			continue;
        }
		
		// Otherwise, add this as a change
		[changes setObject:currentDiff forKey:[thisMember keyName]];
	}

	return changes;	
}

// Apply an incoming diff to this entity instance
- (BOOL)applyDiffFromDictionary:(NSDictionary *)diff toObject:(id<SPDiffable>)object error:(NSError **)error {
	// Process each change in the diff
	for (NSString *key in diff.allKeys) {
        NSDictionary *change    = diff[key];
        NSString *operation     = [change[OP_OP] lowercaseString];
		
        // Failsafe: This should never happen
        if (change == nil) {
            continue;
        }
        
		// Make sure the member exists and is tracked by Simperium
        SPMember *member = [self.schema memberForKey:key];
		if (!member) {
			SPLogWarn(@"Simperium warning: applyDiff for a member that doesn't exist (%@): %@", key, [change description]);
			continue;
		}
		
        if ([operation isEqualToString:OP_OBJECT_ADD] || [operation isEqualToString:OP_OBJECT_REPLACE]) {
            // Newly added / replaced member: set the value
            id newValue = [member getValueFromDictionary:change key:OP_VALUE object:object];
            [object simperiumSetValue:newValue forKey:key];
        } else if ([operation isEqualToString:OP_OBJECT_REMOVE]) {
            // Set the value to nil for now
            [object simperiumSetValue:nil forKey:key];
            
            // TODO: If an SPMemberEntity is set to nil, there's likely some cleanup that needs to be done
        } else {
            // Changed member
            id thisValue  = [object simperiumValueForKey:member.keyName];
            id otherValue = [member getValueFromDictionary:change key:OP_VALUE object:object];
            
            // Support nil values by converting them to valid default values for the purposes of diffing
            if (thisValue == nil) {
                thisValue = [member defaultValue];
            }
            
            // Build a newValue from thisValue based on otherValue
            NSError *theError   = nil;
            id newValue         = [member applyDiff:thisValue otherValue:otherValue error:&theError];
            
            // On error: halt and relay the error to the caller
            if (theError) {
                if (error) {
                    *error = theError;
                }
                return NO;
            }
            
            [object simperiumSetValue:newValue forKey:key];
        }
    }
    
    return YES;
}

// Same strategy as applyDiff, but do it to the ghost's memberData
// Note that no conversions are necessary here since all data is in JSON-compatible format already
- (BOOL)applyGhostDiffFromDictionary:(NSDictionary *)diff toObject:(id<SPDiffable>)object error:(NSError **)error {
	// Create a copy of the ghost's data and update any members that have changed
	NSMutableDictionary *ghostMemberData = object.ghost.memberData;
	NSMutableDictionary *newMemberData = ghostMemberData ? [ghostMemberData mutableCopy] : [NSMutableDictionary dictionaryWithCapacity:diff.count];
	for (NSString *key in diff.allKeys) {
		NSDictionary *change    = diff[key];
		NSString *operation     = [change[OP_OP] lowercaseString];
        
        // Failsafe: This should never happen
        if (change == nil) {
            continue;
        }
        
        // Make sure the member exists and is tracked by Simperium
        SPMember *member = [self.schema memberForKey:key];
        if (!member) {
            SPLogWarn(@"Simperium warning: applyGhostDiff for a member that doesn't exist (%@): %@", key, [change description]);
            continue;
        }

        if ([operation isEqualToString:OP_OBJECT_ADD] || [operation isEqualToString:OP_REPLACE]) {
            // Newly added / replaced member: set the value
            id otherValue = change[OP_VALUE];
            [newMemberData setObject:otherValue forKey:key];
        } else if ([operation isEqualToString:OP_OBJECT_REMOVE]) {
            [newMemberData removeObjectForKey:key];
        } else {
            // Changed value, need to do a diff (which expects converted values)
            id thisValue  = [member getValueFromDictionary:ghostMemberData key:key object:object];
            id otherValue = [member getValueFromDictionary:change key:OP_VALUE object:object];	
            
            if (thisValue == nil) {
                // The member is in the entity definition, but it wasn't in the ghost. This could happen if you
                // update your schema to have a new member when you release a new version of the app. So use a
                // default value for the diff.
                thisValue = [member defaultValue];
                
            } else if (otherValue == nil) {
                SPLogError(@"Simperium error: member %@ from diff wasn't in change", key);
                continue;
            }
            
            NSError *theError   = nil;
            id newValue         = [member applyDiff:thisValue otherValue:otherValue error:&theError];
            
            // On error: halt and relay the error to the caller
            if (theError) {
                if (error) {
                    *error = theError;
                }
                return NO;
            }

            [member setValue:newValue forKey:key inDictionary:newMemberData];
        }
	}
    
    object.ghost.memberData = newMemberData;
    
    return YES;
}

- (NSDictionary *)transform:(id<SPDiffable>)object diff:(NSDictionary *)diff oldDiff:(NSDictionary *)oldDiff oldGhost:(SPGhost *)oldGhost error:(NSError **)error {
	NSMutableDictionary *newDiff = [NSMutableDictionary dictionary];
	// Transform diff first, and then apply it
	for (NSString *key in diff.allKeys) {
		NSDictionary *change    = diff[key];
		NSDictionary *oldChange = oldDiff[key];
		
		// Make sure the member exists and is tracked by Simperium
		SPMember *member = [self.schema memberForKey:key];
		id ghostValue = [member getValueFromDictionary:oldGhost.memberData key:key object:object];
		if (!member) {
			SPLogError(@"Simperium error: transform diff for a member that doesn't exist (%@): %@", key, [change description]);
			continue;
		}
        
        if (!ghostValue) {
			SPLogError(@"Simperium error: transform diff for a ghost member (ghost %@, memberData %@) that doesn't exist (%@): %@", oldGhost, oldGhost.memberData, key, [change description]);
            continue;
        }
		
		// Could handle some weird cases here related to dynamically adding/removing members; ignore for now
		// (example JS code follows)
		/*if (op['o'] == '+' && b[k]['o'] == '+') {
		  // ...
		} else if (op['o'] == '-' && b[k]['o'] == '-') {
			// a, b trying to delete the same key, since b is applied first, this operation no longer necessary in a
			delete ac[k];
		} else if (b[k]['o'] == '-' && (op['o'] in {'O':1,'L':1,'I':1,'d':1})) {
		 // ...
		 }
			*/
		
        id thisValue            = [member getValueFromDictionary:change key:OP_VALUE object:object];
        id otherValue           = [member getValueFromDictionary:oldChange key:OP_VALUE object:object];
        
        NSError *theError       = nil;
        NSDictionary *newChange = [member transform:thisValue otherValue:otherValue oldValue:ghostValue error:&theError];
		
        // On error: halt and relay the error to the caller
        if (theError) {
            if (error) {
                *error = theError;
            }
            return nil;
        }
        
        if (newChange) {
			[newDiff setObject:newChange forKey:key];
        } else {
			// If there was no transformation required, just use the original change
            NSDictionary *changeCopy = [change copy];
            [newDiff setObject:changeCopy forKey:key];
        }
	}
	
	return newDiff;
}

@end
