//
//  WPToast.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 1/8/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "WordPressAppDelegate.h"
#import "PanelNavigationController.h"
#import "WPToast.h"

@implementation WPToast

+ (WPToast *)sharedInstance
{
    static WPToast *sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[WPToast alloc] init];
    });
    return sharedInstance;
}

+ (void)showToastWithMessage:(NSString *)message andImage:(UIImage *)image
{
    [[self sharedInstance] showToastWithMessage:message andImage:image];
}

- (void)showToastWithMessage:(NSString *)message andImage:(UIImage *)image
{
    PanelNavigationController *panelNavigationController = [self panelNavigationController];
    
    UIView *toastView = [[[NSBundle mainBundle] loadNibNamed:@"ToastView" owner:panelNavigationController options:nil] objectAtIndex:0];
    [toastView setFrame:CGRectMake(0.0f, 0.0f, panelNavigationController.view.frame.size.height, panelNavigationController.view.frame.size.height)];
    [toastView setAlpha:0.1f];
    [toastView setCenter:CGPointMake(panelNavigationController.view.bounds.size.width / 2, panelNavigationController.view.bounds.size.height / 2)];
    [toastView.layer setCornerRadius:20.0f];
    [panelNavigationController.view addSubview:toastView];
    
    UILabel *toastLabel = [[toastView subviews] objectAtIndex:0];
    toastLabel.text = message;
    toastLabel.alpha = 0.0f;
    
    UIImageView *toastIcon = [[toastView subviews] objectAtIndex:1];
    toastIcon.image = image;
    toastIcon.alpha = 0.0f;
    
    [UIView beginAnimations:@"toast_zoom_in" context:(__bridge void *)(toastView)];
    [UIView setAnimationDuration:0.15f];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    toastView.alpha= 1.0f;
    CGFloat toastOffset = 95.0f;
    if (IS_IPHONE && UIInterfaceOrientationIsPortrait(panelNavigationController.interfaceOrientation))
        toastOffset = 125.0f;
    toastView.frame = CGRectMake((panelNavigationController.view.bounds.size.width / 2) - 95.0f, (panelNavigationController.view.bounds.size.height / 2) - toastOffset, 190.0f, 190.0f);
    [UIView commitAnimations];    
}

- (void)animationDidStop:(NSString*)animationID finished:(BOOL)finished context:(void *)context {
    PanelNavigationController *panelNavigationController = [self panelNavigationController];
    
    UIView *toastView = (__bridge UIView *)context;
    if([animationID isEqualToString:@"toast_zoom_in"]) {
        UILabel *toastLabel = [[toastView subviews] objectAtIndex:0];
        UIImageView *toastIcon = [[toastView subviews] objectAtIndex:1];
        [UIView beginAnimations:@"content_fade_in" context:(__bridge void *)(toastView)];
        [UIView setAnimationDuration:0.35f];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        toastLabel.alpha = 1.0f;
        toastIcon.alpha = 1.0f;
        [UIView commitAnimations];
    } else if ([animationID isEqualToString:@"content_fade_in"]) {
        UILabel *toastLabel = [[toastView subviews] objectAtIndex:0];
        UIImageView *toastIcon = [[toastView subviews] objectAtIndex:1];
        [UIView beginAnimations:@"content_fade_out" context:(__bridge void *)(toastView)];
        [UIView setAnimationDelay:0.35f];
        [UIView setAnimationDuration:0.25f];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        toastLabel.alpha = 0.0f;
        toastIcon.alpha = 0.0f;
        [UIView commitAnimations];
    }else if ([animationID isEqualToString:@"content_fade_out"]) {
        [UIView beginAnimations:@"toast_zoom_out" context:(__bridge void *)(toastView)];
        [UIView setAnimationDuration:0.15f];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        CGFloat toastOffset = 95.0f;
        if (IS_IPHONE && UIInterfaceOrientationIsPortrait(panelNavigationController.interfaceOrientation))
            toastOffset = 125.0f;
        toastView.frame = CGRectMake(panelNavigationController.view.bounds.size.width / 2, panelNavigationController.view.bounds.size.height / 2, 0.0f, 0.0f);
        toastView.alpha = 0.0f;
        [UIView commitAnimations];
    } else if ([animationID isEqualToString:@"toast_zoom_out"]) {
        [toastView removeFromSuperview];
    }
}

- (PanelNavigationController *)panelNavigationController
{
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    return appDelegate.panelNavigationController;
}

@end
