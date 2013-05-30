//
//  ReaderTableViewCell.h
//  WordPress
//
//  Created by Eric J on 5/15/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DTCoreText/DTCoreText.h>
#import "UIImageView+Gravatar.h"
#import "WordPressAppDelegate.h"

@interface ReaderTableViewCell : UITableViewCell <DTAttributedTextContentViewDelegate>

@property (nonatomic, weak) UIViewController *parentController;
@property (nonatomic, strong) DTAttributedTextContentView *textContentView;
@property (nonatomic, strong) UIImageView *cellImageView;

- (CGFloat)requiredRowHeightForWidth:(CGFloat)width tableStyle:(UITableViewStyle)style;
- (NSAttributedString *)convertHTMLToAttributedString:(NSString *)html withOptions:(NSDictionary *)options;
- (void)handleLinkTapped:(id)sender;

@end
