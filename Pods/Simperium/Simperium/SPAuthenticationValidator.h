//
//  SPAuthenticationValidator.h
//  Simperium-OSX
//
//  Created by Michael Johnston on 8/14/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPAuthenticationValidator : NSObject

@property (nonatomic, assign) NSUInteger minimumPasswordLength;

- (BOOL)validateUsername:(NSString *)username;
- (BOOL)validatePasswordSecurity:(NSString *)password;

@end
