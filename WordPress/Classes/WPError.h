/*
 * WPError.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */


@interface WPError : NSObject

+ (void)showAlertWithError:(NSError *)error title:(NSString *)title;
+ (void)showAlertWithError:(NSError *)error;

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
+ (void)showXMLRPCErrorAlert:(NSError *)error;

@end
