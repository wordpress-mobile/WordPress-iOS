//
//  Config.m
//  SimperiumTests
//
//  Created by Michael Johnston on 11-03-08.
//  Copyright 2011 Simperium. All rights reserved.
//

#import "Config.h"


@implementation Config
@dynamic warpSpeed;
@dynamic binaryFile;
@dynamic captainsLog;
@dynamic shieldsUp;
@dynamic shieldPercent;
@dynamic cost;
@dynamic date;

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // Try setting to nil to make sure it works
    self.captainsLog = nil;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Config\n\twarpSpeed: %d\n\tcaptainsLog:%@\n\tshieldPercent:%f\n",
            [self.warpSpeed intValue], self.captainsLog, [self.shieldPercent floatValue]];
}

- (BOOL)isEqualToObject:(TestObject *)otherObj {
    Config *other = (Config *)otherObj;
    
    // Manual comparison (be paranoid and don't trust Simperium diff)
    BOOL warpSpeedEqual = (self.warpSpeed == nil && other.warpSpeed == nil) || [self.warpSpeed isEqualToNumber:other.warpSpeed];
    BOOL captainsLogEqual = (self.captainsLog == nil && other.captainsLog == nil) || [self.captainsLog isEqualToString:other.captainsLog];
    BOOL shieldsUpEqual = (self.shieldsUp == nil && other.shieldsUp == nil) || [self.shieldsUp isEqualToNumber:other.shieldsUp];
    BOOL shieldPercentEqual = (self.shieldPercent == nil && other.shieldPercent == nil) || [self.shieldPercent floatValue] == [other.shieldPercent floatValue];
    BOOL costEqual = (self.cost == nil && other.cost == nil) || [self.shieldPercent floatValue] == [other.shieldPercent floatValue];
	
	// NOTE: Compare the description (and not the date itself). There might be differences for less than a second!
    BOOL dateEqual = (self.date == nil && other.date == nil) || [self.date.description isEqual:other.date.description];
    
    // Separate BOOLs for easier debugging
    BOOL isEqual = warpSpeedEqual && captainsLogEqual && shieldsUpEqual && shieldPercentEqual && costEqual && dateEqual;
    
    if (!isEqual) {
        NSLog(@"Argh, Config not equal");
	}
    
    return isEqual;
}

@end
