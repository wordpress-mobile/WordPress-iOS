#import "EditReplyViewController.h"



@implementation EditReplyViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Edit Reply", @"");
    self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Send", @"");
    self.content = [NSString string];
}

@end
