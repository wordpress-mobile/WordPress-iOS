//
//  FullscreenImageBrowserViewController.h
//  WordPress
//
//  Created by Maxime Biais on 20/05/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FullscreenImageBrowserViewController : UIViewController {
    IBOutlet UIImageView *imageView;
}
- (id)init;
- (void)setImage:(UIImage *)image;
- (void)dismiss;
@end
