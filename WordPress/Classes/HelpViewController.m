//
//  Help.m
//  WordPress
//
//  Created by Dan Roundhill on 2/15/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "HelpViewController.h"
#import "WPWebViewController.h"

@implementation HelpViewController

@synthesize helpText, faqButton, forumButton, isBlogSetup;



- (void)viewDidUnload {
    [super viewDidUnload];
    
    self.faqButton = nil;
    self.forumButton = nil;
    self.helpText = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
	
    self.navigationItem.title = NSLocalizedString(@"Help", @"");
    
    if (!isBlogSetup) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                      style:[WPStyleGuide barButtonStyleForDone]
                                                     target:self
                                                     action:@selector(cancel:)];

        self.navigationItem.leftBarButtonItem = doneButton;
    }
    
    self.view.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    
    self.helpText.text = NSLocalizedString(@"Please visit the FAQ to get answers to common questions. If you're still having trouble, please post in the forums.", @"");
    self.helpText.font = [WPStyleGuide regularTextFont];
    self.helpText.textColor = [WPStyleGuide littleEddieGrey];
    
    if (IS_IOS7) {
        [self.faqButton setBackgroundImage:nil forState:UIControlStateNormal];
        [self.faqButton setBackgroundImage:nil forState:UIControlStateHighlighted];
        [self.faqButton setTitleColor:[WPStyleGuide buttonActionColor] forState:UIControlStateNormal];
    } else {
        self.faqButton.titleLabel.textColor = [WPStyleGuide littleEddieGrey];
    }
    [self.faqButton setTitle:NSLocalizedString(@"Visit the FAQ", @"") forState:UIControlStateNormal];
    self.faqButton.titleLabel.font = [WPStyleGuide postTitleFont];
    
    if (IS_IOS7) {
        [self.forumButton setBackgroundImage:nil forState:UIControlStateNormal];
        [self.forumButton setBackgroundImage:nil forState:UIControlStateHighlighted];
        [self.forumButton setTitleColor:[WPStyleGuide buttonActionColor] forState:UIControlStateNormal];
    } else {
        self.forumButton.titleLabel.textColor = [WPStyleGuide littleEddieGrey];        
    }
    [self.forumButton setTitle:NSLocalizedString(@"Visit the Forums", @"") forState:UIControlStateNormal];
    self.forumButton.titleLabel.font = [WPStyleGuide postTitleFont];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

-(void)cancel: (id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)helpButtonTap: (id)sender {
    WPWebViewController *webViewController = [[WPWebViewController alloc] init];
    UIButton *button = (UIButton*)sender;
    if (button.tag == 0)
        [webViewController setUrl:[NSURL URLWithString:@"http://ios.wordpress.org/faq"]];
    else
        [webViewController setUrl:[NSURL URLWithString:@"http://ios.forums.wordpress.org"]];
    [self.navigationController pushViewController:webViewController animated:YES];
}





@end
