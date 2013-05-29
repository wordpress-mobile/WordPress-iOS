//
//  WPComLanguages.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/11/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPComLanguages.h"

@interface WPComLanguages()

@property (nonatomic, strong) NSArray *languages;

@end

@implementation WPComLanguages

- (id)init
{
    self = [super init];
    if (self) {
        [self initializeLanguages];
    }
    return self;
}

+ (NSDictionary *)currentLanguage
{
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSDictionary *currentLanguage = [WPComLanguages languageDataForLocale:language];
    if (currentLanguage == nil) {
        currentLanguage = [WPComLanguages languageDataForLocale:@"en"];
    }
    
    return currentLanguage;
}

+ (NSArray *)allLanguages
{
    return [self sharedInstance].languages;
}

+ (NSDictionary *)languageDataForLocale:(NSString *)locale
{
    NSArray *languages = [self sharedInstance].languages;
    
    for (NSDictionary *languageData in languages) {
        if ([[languageData objectForKey:@"slug"] isEqualToString:locale])
            return languageData;
    }
    
    return nil;
}

#pragma mark - Private Methods

+ (WPComLanguages *)sharedInstance
{
    static WPComLanguages *sharedInstance = nil;
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (void)initializeLanguages
{
    NSBundle* bundle = [NSBundle mainBundle];
	NSString* plistPath = [bundle pathForResource:@"DotCom-Languages" ofType:@"plist"];
    _languages = [[NSArray alloc] initWithContentsOfFile:plistPath];
}

@end
