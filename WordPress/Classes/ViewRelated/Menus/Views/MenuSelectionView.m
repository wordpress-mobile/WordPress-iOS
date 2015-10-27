//
//  MenuSelectionView.m
//  WordPress
//
//  Created by Kurzee on 10/26/15.
//  Copyright © 2015 WordPress. All rights reserved.
//

#import "MenuSelectionView.h"

@implementation MenuSelectionView

- (CGSize)intrinsicContentSize
{
    CGSize size = [super intrinsicContentSize];
    size.width = 200;
    size.height = 100;
    
    return size;
}

@end
