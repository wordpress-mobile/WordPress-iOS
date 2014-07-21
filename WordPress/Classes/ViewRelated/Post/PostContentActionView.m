#import "PostContentActionView.h"
#import "Post.h"
#import "NSDate+StringFormatting.h"

@implementation PostContentActionView

#pragma mark - Timer Related

- (void)refreshDate:(NSTimer *)timer
{
    NSString *title = [[self.contentProvider dateForDisplay] longString];
    [self.timeButton setTitle:title forState:UIControlStateNormal | UIControlStateDisabled];
}

@end
