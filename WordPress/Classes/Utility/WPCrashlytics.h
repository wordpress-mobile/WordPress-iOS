//
//  WPCrashlytics.h
//  WordPress
//
//  Created by Diego E. Rey Mendez on 3/26/15.
//  Copyright (c) 2015 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  @class      WPCrashlytics
 *  @brief      This module contains the crashlytics logic for WPiOS.
 */
@interface WPCrashlytics : NSObject

- (instancetype)initWithAPIKey:(NSString*)apiKey;

@end
