//
//  DTASN1Serialization.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 3/9/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTASN1Parser.h"

@interface DTASN1Serialization : NSObject

+ (id)objectWithData:(NSData *)data;

@end
