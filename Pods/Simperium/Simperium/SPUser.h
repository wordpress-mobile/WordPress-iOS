//
//  SPUser.h
//  Simperium
//
//  Created by Michael Johnston on 11-06-03.
//  Copyright 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SPUser : NSObject

@property (copy, nonatomic, readwrite) NSString *email;
@property (copy, nonatomic, readwrite) NSString *authToken;

- (id)initWithEmail:(NSString *)username token:(NSString *)token;
- (NSString *)hashedEmail;
- (BOOL)authenticated;

// Stubs that will eventually allow you to store/retrieve custom user data
- (void)setCustomObject:(id)object forKey:(NSString *)key;
- (id)getCustomObjectForKey:(NSString *)key;

@end
