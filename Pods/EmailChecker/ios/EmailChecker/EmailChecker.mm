//
//  EmailChecker.m
//  EmailChecker
//
//  Created by Maxime Biais on 12/11/2013.
//  Copyright (c) 2013 Automattic. All rights reserved.
//

#import "EmailChecker.h"
#import "EmailDomainSpellChecker.h"
#import <string>

@implementation EmailChecker

+ (NSString *) suggestDomainCorrection:(NSString *)email {
    EmailDomainSpellChecker edsc;
    std::string stdEmail([email UTF8String]);
    std::string suggested = edsc.suggestDomainCorrection(stdEmail);
    return [NSString stringWithCString:suggested.c_str()
                              encoding:[NSString defaultCStringEncoding]];
}

@end
