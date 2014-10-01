#import "EditReplyViewController.h"



@implementation EditReplyViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Edit Reply", @"Comment Reply Screen title");
    self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Send", @"Verb, submit a comment reply");
    self.content = [NSString string];
}

@end
