//
//  SelectWPComLanguageViewController.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/10/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SelectWPComLanguageViewControllerDelegate;
@interface SelectWPComLanguageViewController : UITableViewController

@property (nonatomic, weak) id<SelectWPComLanguageViewControllerDelegate> delegate;
@property (nonatomic, assign) NSInteger currentlySelectedLanguageId;

@end

@protocol SelectWPComLanguageViewControllerDelegate <NSObject>

- (void)selectWPComLanguageViewController:(SelectWPComLanguageViewController *)viewController didSelectLanguage:(NSDictionary *)data;

@end