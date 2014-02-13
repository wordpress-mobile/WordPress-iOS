//
//  ReaderButton.m
//  WordPress
//
//  Created by Jorge Bernal on 6/27/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderButton.h"

@implementation ReaderButton

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.alpha = highlighted ? .5f : 1.f;
}

@end
