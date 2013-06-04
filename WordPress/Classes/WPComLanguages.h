//
//  WPComLanguages.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/11/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WPComLanguages : NSObject

+ (NSDictionary *)currentLanguage;
+ (NSArray *)allLanguages;
+ (NSDictionary *)languageDataForLocale:(NSString *)locale;

@end
