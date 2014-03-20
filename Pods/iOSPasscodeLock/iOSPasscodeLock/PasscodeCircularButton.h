/*
 *  PasscodeCircularButton.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */


#import <UIKit/UIKit.h>
#import "PasscodeButtonStyleProvider.h"

@interface PasscodeCircularButton : UIButton

- (id)initWithNumber:(NSString *)number frame:(CGRect)frame style:(PasscodeButtonStyle *)style;

@end
