//
//  DetailViewController.h
//  WordPressApiExample
//
//  Created by Jorge Bernal on 12/20/11.
//  Copyright (c) 2011 Automattic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PostViewController : UIViewController

@property (strong, nonatomic) NSDictionary *post;

@property (strong, nonatomic) IBOutlet UIWebView *postContentView;

@end
