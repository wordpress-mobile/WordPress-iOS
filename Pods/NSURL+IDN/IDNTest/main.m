//
//  main.m
//  IDNTest
//
//  Created by Jorge Bernal on 4/8/11.
//  Copyright 2011 Automattic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSURL+IDN.h"

void testIDN(NSString *decoded, NSString *expected) {
    NSString *encoded = [NSURL IDNEncodedHostname:decoded];
    if ([encoded isEqualToString:expected])
        NSLog(@"%@ -> %@", decoded, encoded);
    else
        NSLog(@"%@ -> %@ (Expected: %@)", decoded, encoded, expected);
}

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    testIDN(@"http://test.soymaño.com", @"http://test.xn--soymao-0wa.com");
    testIDN(@"إختبار", @"xn--kgbechtv");
    testIDN(@"испытание", @"xn--80akhbyknj4f");

    [pool drain];
    return 0;
}

