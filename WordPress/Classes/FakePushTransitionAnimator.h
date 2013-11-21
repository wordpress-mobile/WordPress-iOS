//
//  FakePushTransitionAnimator.h
//  WordPress
//
//  Created by Jorge Bernal on 21/11/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FakePushTransitionAnimator : NSObject <UIViewControllerAnimatedTransitioning>
@property (nonatomic, assign, getter = isPresenting) BOOL presenting;
@end
