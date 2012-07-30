//
//  PanelViewWrapper.h
//  WordPress
//
//  Created by Eric Johnson on 6/12/12.
//

#import <UIKit/UIKit.h>

@interface PanelViewWrapper : UIView

@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, getter=isToolbarHidden) BOOL toolbarHidden;
@property (nonatomic, strong) UIView *overlay;

- (id)initWithViewController:(UIViewController *)controller;

- (void)wrapViewFromController:(UIViewController *)controller;
- (NSArray *)toolbarItems;
- (void)setToolbarItems:(NSArray *)items;
- (void)setToolbarItems:(NSArray *)items animated:(BOOL)animated;
- (void)setToolbarHidden:(BOOL)hidden animated:(BOOL)animated;
- (BOOL)isToolbarHidden;
- (void)handleToolbarChanged:(NSNotification *)notification;

@end
