//
//  WPAppAnalytics.h
//  WordPress
//
//  Created by Diego E. Rey Mendez on 3/16/15.
//  Copyright (c) 2015 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const WPAppAnalyticsDefaultsKeyUsageTracking;

/**
 *  @class      WPAppAnalytics
 *  @brief      This is a container for the app-specific analytics logic.
 *  @details    WPAnalytics is a generic component.  This component acts as a container for all
 *              of the WPAnalytics code that's specific to WordPress, interfacing with WPAnalytics
 *              where appropiate.  This is mostly useful to remove such app-specific logic from
 *              our app delegate class.
 */
@interface WPAppAnalytics : NSObject

#pragma mark - App Tracking

/**
 *  @brief      Tracks that the application has been closed.
 *  
 *  @param      lastVisibleScreen       The name of the last visible screen.  Can be nil.
 */
- (void)trackApplicationClosed:(NSString*)lastVisibleScreen;

/**
 *  @brief      Tracks that the application has been opened.
 */
- (void)trackApplicationOpened;

@end
