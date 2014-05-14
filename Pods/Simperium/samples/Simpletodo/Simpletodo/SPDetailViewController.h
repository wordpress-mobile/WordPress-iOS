//
//  SPDetailViewController.h
//  Simpletodo
//
//  Created by Michael Johnston on 12-02-15.
//  Copyright (c) 2012 Simperium. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Todo;

@interface SPDetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) Todo *detailItem;

@property (weak, nonatomic) IBOutlet UITextField *textField;

@end
