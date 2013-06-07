//
//  ActivityLogDetailViewController.m
//  WordPress
//
//  Created by Aaron Douglas on 6/7/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ActivityLogDetailViewController.h"
#import <QuartzCore/QuartzCore.h>


@interface ActivityLogDetailViewController ()

@property (nonatomic, strong) NSString *logText;
@property (nonatomic, strong) NSString *logDate;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIPopoverController *popover;

@end

@implementation ActivityLogDetailViewController

- (id)initWithLog:(NSString *)logText forDateString:(NSString *)logDate
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _logText = logText;
        _logDate = logDate;
        self.title = logDate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"settings_bg"]];

    CGRect frame = CGRectInset(self.view.bounds, 10, 10);
    self.textView = [[UITextView alloc] initWithFrame:frame];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.textView.editable = NO;
    self.textView.layer.cornerRadius = 5.0;
    self.textView.text = self.logText;
    [self.view addSubview:self.textView];

    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"UIButtonBarActionBlack.png"]
                                                      landscapeImagePhone:[UIImage imageNamed:@"UIButtonBarActionSmallBlack.png"]
                                                                    style:UIBarButtonItemStyleBordered
                                                                   target:self
                                                                   action:@selector(showShareOptions:)];
    self.navigationItem.rightBarButtonItem = shareButton;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showShareOptions:(id)sender
{
    if (NSClassFromString(@"UIActivityViewController") != nil) {
        // If UIActivityViewController is available, use it (iOS 6+)
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self.logText]
                                                                                             applicationActivities:nil];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            if (self.popover) {
                [self.popover dismissPopoverAnimated:YES];
                self.popover = nil;
            } else {
                self.popover = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
                [self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
        } else {
            [self presentViewController:activityViewController animated:YES completion:nil];
        }
    } else {
        // Otherwise, flip back to an action sheet for < iOS 6
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Share", @"")
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:NSLocalizedString(@"Mail", @""), nil];

        [actionSheet showFromBarButtonItem:sender animated:YES];
    }

}
@end
