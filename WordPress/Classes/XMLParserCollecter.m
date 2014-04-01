//
//  XMLParserCollecter.m
//  WordPress
//
//  Created by Jorge Leandro Perez on 3/31/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "XMLParserCollecter.h"



@implementation XMLParserCollecter

- (id)init {
    if (self = [super init]) {
        self.result = [[NSMutableString alloc] init];
    }
    return self;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [self.result appendString:string];
}

@end
