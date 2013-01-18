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

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];
	
    self.navigationItem.title = NSLocalizedString(@"Help", @"");
    
    if (!isBlogSetup) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                   style:UIBarButtonItemStyleDone target:self action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = doneButton;
    }
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"welcome_bg_pattern.png"]];
    
    self.helpText.text = NSLocalizedString(@"Please visit the FAQ to get answers to common questions. If you're still having trouble, please post in the forums.", @"");
    [self.faqButton setTitle:NSLocalizedString(@"Visit the FAQ", @"") forState:UIControlStateNormal];
    [self.forumButton setTitle:NSLocalizedString(@"Visit the Forums", @"") forState:UIControlStateNormal];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

-(void)cancel: (id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

-(void)helpButtonTap: (id)sender {
    WPWebViewController *webViewController = nil;
    if ( IS_IPAD ) {
        webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil];
    }
    else {
        webViewController = [[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil];
    }
    UIButton *button = (UIButton*)sender;
    if (button.tag == 0)
        [webViewController setUrl:[NSURL URLWithString:@"http://ios.wordpress.org/faq"]];
    else
        [webViewController setUrl:[NSURL URLWithString:@"http://ios.forums.wordpress.org"]];
    [self.navigationController pushViewController:webViewController animated:YES];
}





@end
