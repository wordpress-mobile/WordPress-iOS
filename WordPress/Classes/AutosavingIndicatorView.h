//
//  AutosavingIndicatorView.h
//  WordPress
//
//  Created by Jorge Bernal on 1/24/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AutosavingIndicatorView : UIView

- (void)startAnimating;
- (void)stopAnimatingWithSuccess:(BOOL)success;

@end
