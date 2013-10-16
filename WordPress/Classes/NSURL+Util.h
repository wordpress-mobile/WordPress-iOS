//
//  NSURL+Util.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 7/18/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (Util)

- (BOOL)isWordPressDotComUrl;
- (NSURL *)ensureSecureURL;

@end
