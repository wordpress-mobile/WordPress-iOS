//
//  SelectWPComLanguageViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/10/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^SelectWPComLanguageViewControllerBlock)(NSDictionary *);

@interface SelectWPComLanguageViewController : UITableViewController

@property (nonatomic, assign) NSInteger currentlySelectedLanguageId;
@property (nonatomic, copy) SelectWPComLanguageViewControllerBlock didSelectLanguage;

@end