//
//  EmailChecker.h
//  EmailChecker
//
//  Created by Maxime Biais on 12/11/2013.
//  Copyright (c) 2013 Automattic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EmailChecker : NSObject

+ (NSString *) suggestDomainCorrection:(NSString *)email;

@end
