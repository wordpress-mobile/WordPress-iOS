//
//  WPLivePreviewWorkaroundWebViewManager.h
//  WordPress
//
//  Created by Josh Avant on 7/30/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "WPAuthenticatedSessionWebViewManager.h"

// This class will cause all requests to force the Desktop Site layout

@interface WPDesktopSiteWebViewManager : WPAuthenticatedSessionWebViewManager

@end
