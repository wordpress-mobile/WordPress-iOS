//
//  QuickPhotoUploadProgressController.h
//  WordPress
//
//  Created by Dan Roundhill on 4/26/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface QuickPhotoUploadProgressController : UIViewController {
    
    IBOutlet UILabel *label;
    IBOutlet UIActivityIndicatorView *spinner;
    
}

@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;


@end
