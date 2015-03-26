//
//  WPLogger.h
//  WordPress
//
//  Created by Diego E. Rey Mendez on 3/26/15.
//  Copyright (c) 2015 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WPLogger : NSObject

#pragma mark - Reading from the log

- (NSString *)getLogFilesContentWithMaxSize:(NSInteger)maxSize;

@end
