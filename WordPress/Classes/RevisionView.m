//
//  RevisionView.m
//  WordPress
//
//  Created by Maxime Biais on 10/07/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "RevisionView.h"

@implementation RevisionView

- (void)initStyle {
    self.layer.cornerRadius = 10;
    self.layer.masksToBounds = YES;
    self.layer.borderWidth = 1;
    self.layer.borderColor = [UIColor grayColor].CGColor;
}

@end
