//
//  GrowingImageView.h
//  WordPress
//
//  Created by Brennan Stehling on 8/14/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GrowingImageView : UIImageView

@property (weak, nonatomic) IBOutlet UIView *fullView;

- (void)growFullImageView:(BOOL)animated;
- (void)shrinkFullImageView:(BOOL)animated;

@end
