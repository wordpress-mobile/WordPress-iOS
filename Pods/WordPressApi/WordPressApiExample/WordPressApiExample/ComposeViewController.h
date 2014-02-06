//
//  ComposeViewController.h
//  WordPressApiExample
//
//  Created by Jorge Bernal on 1/17/12.
//  Copyright (c) 2012 Automattic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ComposeViewController : UIViewController
@property (nonatomic, retain) IBOutlet UITextField *titleField;
@property (nonatomic, retain) IBOutlet UITextView *content;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) UIImage *image;
- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)addPicture:(id)sender;
@end
