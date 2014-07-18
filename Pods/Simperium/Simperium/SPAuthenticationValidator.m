//
//  SPAuthenticationValidator.m
//  Simperium-OSX
//
//  Created by Michael Johnston on 8/14/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "SPAuthenticationValidator.h"

static int kDefaultMinimumPasswordLength = 4;

@implementation SPAuthenticationValidator
@synthesize minimumPasswordLength;

- (id)init {
    if ((self = [super init])) {
        self.minimumPasswordLength = kDefaultMinimumPasswordLength;
    }
    
    return self;
}

- (BOOL)isValidEmail:(NSString *)checkString {
    // From http://stackoverflow.com/a/3638271/1379066
    BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:checkString];
}

- (BOOL)validateUsername:(NSString *)username {
    // Expect email addresses by default
    return [self isValidEmail:username];
}

- (BOOL)validatePasswordSecurity:(NSString *)password {
    if ([password length] < self.minimumPasswordLength) {
        return NO;
    }
    
    // Could enforce other requirements here
    return YES;
}


@end
