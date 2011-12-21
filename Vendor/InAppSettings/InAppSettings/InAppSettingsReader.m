//
//  InAppSettingsReader.m
//  InAppSettingsTestApp
//
//  Created by David Keegan on 1/19/10.
//  Copyright 2010 InScopeApps{+}. All rights reserved.
//

#import "InAppSettingsReader.h"
#import "InAppSettingsSpecifier.h"
#import "InAppSettingsConstants.h"

@implementation InAppSettingsReaderRegisterDefaults

@synthesize files;
@synthesize values;

- (void)loadFile:(NSString *)file{
    //if the file is not in the files list we havn't read it yet
    NSInteger fileIndex = [self.files indexOfObject:file];
    if(fileIndex == NSNotFound){
        [self.files addObject:file];
        
        //load plist
        NSDictionary *settingsDictionary = [[NSDictionary alloc] initWithContentsOfFile:InAppSettingsFullPlistPath(file)];
        NSArray *preferenceSpecifiers = [settingsDictionary objectForKey:InAppSettingsPreferenceSpecifiers];
        NSString *stringsTable = [settingsDictionary objectForKey:InAppSettingsStringsTable];
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        for(NSDictionary *eachSetting in preferenceSpecifiers){
            InAppSettingsSpecifier *setting = [[InAppSettingsSpecifier alloc] initWithDictionary:eachSetting andStringsTable:stringsTable];
            if([setting isValid]){
                if([setting isType:InAppSettingsPSChildPaneSpecifier]){
                    [self loadFile:[setting valueForKey:InAppSettingsSpecifierFile]];
                }else if([setting hasKey]){
                    if([setting valueForKey:InAppSettingsSpecifierDefaultValue]){
                        [self.values 
                            setObject:[setting valueForKey:InAppSettingsSpecifierDefaultValue] 
                            forKey:[setting getKey]];
                    }
                }
            }
            [setting release];
        }
        [pool drain];
        [settingsDictionary release];
    }
}

- (id)init{
    self = [super init];
    if (self != nil) {
        self.files = [[NSMutableArray alloc] init];
        self.values = [[NSMutableDictionary alloc] init];
        [self loadFile:InAppSettingsRootFile];
        [[NSUserDefaults standardUserDefaults] registerDefaults:self.values];
    }
    return self;
}


- (void)dealloc{
    [files release];
    [values release];
    [super dealloc];
}

@end

@implementation InAppSettingsReader

@synthesize file;
@synthesize headers, settings;

- (id)initWithFile:(NSString *)inputFile{
    self = [super init];
    if(self != nil){
        self.file = inputFile;
        
        //load plist
        NSDictionary *settingsDictionary = [[NSDictionary alloc] initWithContentsOfFile:InAppSettingsFullPlistPath(self.file)];
        NSArray *preferenceSpecifiers = [settingsDictionary objectForKey:InAppSettingsPreferenceSpecifiers];
        NSString *stringsTable = [settingsDictionary objectForKey:InAppSettingsStringsTable];
        
        //initialize the arrays
        self.headers = [[NSMutableArray alloc] init];
        self.settings = [[NSMutableArray alloc] init];
        
        //load the data
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        for(NSDictionary *eachSetting in preferenceSpecifiers){
            InAppSettingsSpecifier *setting = [[InAppSettingsSpecifier alloc] initWithDictionary:eachSetting andStringsTable:stringsTable];
            if([setting isValid]){
                if([setting isType:InAppSettingsPSGroupSpecifier]){
                    [self.headers addObject:[setting localizedTitle]];
                    [self.settings addObject:[NSMutableArray array]];
                }else{
                    //if there are no settings make an initial container
                    if([self.settings count] < 1){
                        [self.headers addObject:@""];
                        [self.settings addObject:[NSMutableArray array]];
                    }
                    [[self.settings lastObject] addObject:setting];
                }
            }
            [setting release];
        }
        [pool drain];
        [settingsDictionary release];
    }
    return self;
}

- (void)dealloc{
    [file release];
    [headers release];
    [settings release];
    [super dealloc];
}

@end
