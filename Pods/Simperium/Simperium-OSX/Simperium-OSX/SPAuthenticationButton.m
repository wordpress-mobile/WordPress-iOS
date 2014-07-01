//
//  SPAuthenticationButton.m
//  Simplenote-OSX
//
//  Created by Michael Johnston on 7/24/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "SPAuthenticationButton.h"
#import "SPAuthenticationButtonCell.h"

@implementation SPAuthenticationButton

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    
    return self;
}

+ (void)load {
    [[self class] setCellClass:[SPAuthenticationButtonCell class]];
}

@end
