//
//  PSTitleValueSpecifierCell.m
//  InAppSettingsTestApp
//
//  Created by David Keegan on 11/21/09.
//  Copyright 2009 InScopeApps{+}. All rights reserved.
//

#import "InAppSettingsPSTitleValueSpecifierCell.h"
#import "InAppSettingsConstants.h"

@implementation InAppSettingsPSTitleValueSpecifierCell

- (NSString *)getValueTitle{
    NSArray *titles = [self.setting valueForKey:InAppSettingsSpecifierTitles];
    NSArray *values = [self.setting valueForKey:InAppSettingsSpecifierValues];
    if(titles || values){
        if(([titles count] == 0) || ([values count] == 0) || ([titles count] != [values count])){
            return nil;
        }
        NSInteger valueIndex = [values indexOfObject:[self.setting getValue]];
        if((valueIndex >= 0) && (valueIndex < (NSInteger)[titles count])){
            return [titles objectAtIndex:valueIndex];
        }
        
        return nil;
    }
    
    return [self.setting getValue];
}

- (void)setUIValues{
    [super setUIValues];
    
    [self setTitle];
    
    if([self.setting valueForKey:InAppSettingsSpecifierInAppURL]){
        [self setDisclosure:YES];
        self.canSelectCell = YES;
    }
    
    [self setDetail:[self getValueTitle]];
}

@end
