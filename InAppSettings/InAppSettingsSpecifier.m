//
//  InAppSetting.m
//  InAppSettingsTestApp
//
//  Created by David Keegan on 11/21/09.
//  Copyright 2009 InScopeApps{+}. All rights reserved.
//

#import "InAppSettings.h"
#import "InAppSettingsSpecifier.h"
#import "InAppSettingsConstants.h"

@implementation InAppSettingsSpecifier

@synthesize stringsTable;

- (NSString *)getKey{
    return [self valueForKey:InAppSettingsSpecifierKey];
}

- (NSString *)getType{
    return [self valueForKey:InAppSettingsSpecifierType];
}

- (BOOL)isType:(NSString *)type{
    return [[self getType] isEqualToString:type];
}

- (id)valueForKey:(NSString *)key{
    return [settingDictionary objectForKey:key];
}

- (NSString *)localizedTitle{
    NSString *title = [self valueForKey:InAppSettingsSpecifierTitle];
    if([self valueForKey:InAppSettingsSpecifierInAppTitle]){
        title = [self valueForKey:InAppSettingsSpecifierInAppTitle];
    }
    return InAppSettingsLocalize(title, self.stringsTable);
}

- (NSString *)cellName{
    return [NSString stringWithFormat:@"%@%@Cell", InAppSettingsProjectName, [self getType]];
}

- (id)getValue{
    id value = [[NSUserDefaults standardUserDefaults] valueForKey:[self getKey]];
    if(value == nil){
        value = [self valueForKey:InAppSettingsSpecifierDefaultValue];
    }
    return value;
}

- (void)setValue:(id)newValue{
    NSString *key = [self getKey];
    [[NSUserDefaults standardUserDefaults] setObject:newValue forKey:key];

    NSNotification *notification = [NSNotification notificationWithName:InAppSettingsNotificationName object:key];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

#pragma mark validation

- (BOOL)hasTitle{
    return ([self valueForKey:InAppSettingsSpecifierTitle]) ? YES:NO;
}

- (BOOL)hasKey{
    NSString *key = [self getKey];
    return (key && (![key isEqualToString:@""]));
}

- (BOOL)hasDefaultValue{
    return ([self valueForKey:InAppSettingsSpecifierDefaultValue]) ? YES:NO;
}

- (BOOL)isValid{
    if(![self getType]){
        return NO;
    }
    
    if([self isType:InAppSettingsPSGroupSpecifier]){
        return YES;
    }
    
    if([self isType:InAppSettingsPSMultiValueSpecifier]){
        if(![self hasKey]){
            return NO;
        }
        
        if(![self hasDefaultValue]){
            return NO;
        }
        
        //check the localized and un-locatlized values
        if(![self hasTitle] || [[self valueForKey:InAppSettingsSpecifierTitle] length] == 0){
            return NO;
        }
        
        NSArray *titles = [self valueForKey:InAppSettingsSpecifierTitles];
        if((!titles) || ([titles count] == 0)){
            return NO;
        }
        
        NSArray *values = [self valueForKey:InAppSettingsSpecifierValues];
        if((!values) || ([values count] == 0)){
            return NO;
        }
        
        if([titles count] != [values count]){
            return NO;
        }
        
        return YES;
    }
    
    if([self isType:InAppSettingsPSSliderSpecifier]){
        if(![self hasKey]){
            return NO;
        }
        
        if(![self hasDefaultValue]){
            return NO;
        }
        
        //The settings app allows min>max
        if(![self valueForKey:InAppSettingsSpecifierMinimumValue]){
            return NO;
        }
        
        if(![self valueForKey:InAppSettingsSpecifierMaximumValue]){
            return NO;
        }
        
        return YES;
    }
    
    if([self isType:InAppSettingsPSToggleSwitchSpecifier]){
        if(![self hasKey]){
            return NO;
        }
        
        if(![self hasDefaultValue]){
            return NO;
        }
        
        if(![self hasTitle]){
            return NO;
        }
        
        return YES;
    }
    
    if([self isType:InAppSettingsPSTitleValueSpecifier]){
        if(![self hasKey]){
            return NO;
        }
        
        if(![self hasDefaultValue]){
            return NO;
        }
        
        return YES;
    }
    
    if([self isType:InAppSettingsPSTextFieldSpecifier]){
        if(![self hasKey]){
            return NO;
        }
        
        if(![self hasTitle]){
            return NO;
        }
        
        return YES;
    }
    
    if([self isType:InAppSettingsPSChildPaneSpecifier]){
        if(![self hasTitle]){
            return NO;
        }
        
        if(![self valueForKey:InAppSettingsSpecifierFile]){
            return NO;
        }
        
        return YES;
    }
    
    return NO;
}

#pragma mark init/dealloc

- (id)init{
    return [self initWithDictionary:nil andStringsTable:nil];
}

- (id)initWithDictionary:(NSDictionary *)dictionary andStringsTable:(NSString *)table{
    self = [super init];
    if (self != nil){
        if(dictionary){
            self.stringsTable = table;
            settingDictionary = [dictionary retain];
        }
    }
    return self;
}

- (void)dealloc{
    [stringsTable release];
    [settingDictionary release];
    [super dealloc];
}

@end
