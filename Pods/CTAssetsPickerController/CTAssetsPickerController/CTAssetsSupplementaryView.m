/*
 CTAssetsSupplementaryView.m
 
 The MIT License (MIT)
 
 Copyright (c) 2013 Clement CN Tsang
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import "CTAssetsSupplementaryView.h"



@interface CTAssetsSupplementaryView ()

@end





@implementation CTAssetsSupplementaryView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _label = [self supplementaryLabel];
        [self addSubview:_label];
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_label
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.0f
                                                          constant:0.0f]];
    }
    
    return self;
}

- (UILabel *)supplementaryLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(self.bounds, 8.0, 8.0)];
    label.font = [UIFont systemFontOfSize:18.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    return label;
}

- (void)bind:(NSArray *)assets
{
    NSInteger numberOfVideos = [assets filteredArrayUsingPredicate:[self predicateOfAssetType:ALAssetTypeVideo]].count;
    NSInteger numberOfPhotos = [assets filteredArrayUsingPredicate:[self predicateOfAssetType:ALAssetTypePhoto]].count;
    
    if (numberOfVideos == 0)
        self.label.text = [NSString stringWithFormat:NSLocalizedString(@"%ld Photos", nil), (long)numberOfPhotos];
    else if (numberOfPhotos == 0)
        self.label.text = [NSString stringWithFormat:NSLocalizedString(@"%ld Videos", nil), (long)numberOfVideos];
    else
        self.label.text = [NSString stringWithFormat:NSLocalizedString(@"%ld Photos, %ld Videos", nil), (long)numberOfPhotos, (long)numberOfVideos];
}

- (NSPredicate *)predicateOfAssetType:(NSString *)type
{
    return [NSPredicate predicateWithBlock:^BOOL(ALAsset *asset, NSDictionary *bindings) {
        return [[asset valueForProperty:ALAssetPropertyType] isEqual:type];
    }];
}

@end