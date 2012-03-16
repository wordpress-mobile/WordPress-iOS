//
//  WPAFNetworking.h
//  WordPress
//
//  Created by Jorge Bernal on 11/4/11.
//  Copyright (c) 2011 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Availability.h>

#ifndef _AFNETWORKING_
#define _AFNETWORKING_

#import "AFURLConnectionOperation.h"

#import "AFHTTPRequestOperation.h"
#import "AFXMLRequestOperation.h"
#import "AFPropertyListRequestOperation.h"

#import "AFImageRequestOperation.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import "AFNetworkActivityIndicatorManager.h"
#import "UIImageView+AFNetworking.h"
#endif

#endif /* _AFNETWORKING_ */