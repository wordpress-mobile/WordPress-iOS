//
//  NotificationsDetailViewController.h
//  WordPress
//
//  Created by Beau Collins on 11/20/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IOS7CorrectedTextView, Note;

@interface NotificationsCommentDetailViewController : UIViewController <UITextViewDelegate>

- (id)initWithNote:(Note *)note;

@end
