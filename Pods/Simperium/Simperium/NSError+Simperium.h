//
//  NSError+Simperium.h
//  Simperium
//
//  Created by Jorge Leandro Perez on 4/14/14.
//  Copyright (c) 2014 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSError ()

+ (NSError*)errorWithDomain:(NSString*)errorDomain code:(NSInteger)errorCode description:(NSString*)description;

@end
