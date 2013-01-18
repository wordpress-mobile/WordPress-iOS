//
//  WPError.h
//  WordPress
//
//  Created by Jorge Bernal on 4/17/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WPError : NSObject

+ (NSError *)errorWithResponse:(NSHTTPURLResponse *)response error:(NSError *)error;

+ (void)showAlertWithError:(NSError *)error title:(NSString *)title;

+ (void)showAlertWithError:(NSError *)error;

@end
