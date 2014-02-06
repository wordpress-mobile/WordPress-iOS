//
//  MixpanelDummyHTTPConnection.h
//  HelloMixpanel
//
//  Created by Alex Hofsteede on 10/23/13.
//  Copyright (c) 2013 Mixpanel. All rights reserved.
//

#import "HTTPConnection.h"

@interface MixpanelDummyHTTPConnection : HTTPConnection

+(int) getRequestCount;

@end
