//
//  XMLRPCDataCleaner.h
//  Based on code from WordPress for iOS http://ios.wordpress.org/
//
//  Created by Jorge Bernal on 12/15/11.
//  Original code by Danilo Ercoli
//  Copyright (c) 2011 WordPress.
//

#import <Foundation/Foundation.h>

@interface XMLRPCDataCleaner : NSObject {
    NSData *xmlData;
}

- (id)initWithData:(NSData *)data;

- (NSData *)cleanData;

@end
