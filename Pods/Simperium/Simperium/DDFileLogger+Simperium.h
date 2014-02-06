//
//  DDFileLogger+Simperium.h
//  Simperium
//
//  Created by Jorge Leandro Perez on 10/30/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "DDFileLogger.h"


@interface DDFileLogger (Simperium)
+ (DDFileLogger*)sharedInstance;
- (NSData*)exportLogfiles;
@end
