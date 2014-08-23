//
//  MockSimperium.h
//  Simperium
//
//  Created by Jorge Leandro Perez on 11/12/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <Simperium/Simperium.h>
#else
#import <Simperium-OSX/Simperium.h>
#endif

#import "MockWebSocketInterface.h"



@interface MockSimperium : Simperium

+ (instancetype)mockSimperium;

- (MockWebSocketInterface*)mockWebSocketInterface;

@end
