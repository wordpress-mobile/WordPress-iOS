#import "RestorePageTableViewCell.h"
#import "WPStyleGuide+Posts.h"

@interface RestorePageTableViewCell()

@property (nonatomic, strong) IBOutlet UIView *pageContentView;
@property (nonatomic, strong) IBOutlet UILabel *restoreLabel;
@property (nonatomic, strong) IBOutlet UIButton *restoreButton;
@property (nonatomic, strong) id<WPPostContentViewProvider>contentProvider;

@end

@implementation RestorePageTableViewCell

@synthesize delegate;

#pragma mark - Life Cycle

- (void)awakeFromNib {
    [super awakeFromNib];

    [self configureView];
    [self applyStyles];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    // Don't respond to taps in margins.
    if (!CGRectContainsPoint(self.pageContentView.frame, point)) {
        return nil;
    }
    return [super hitTest:point withEvent:event];
}


#pragma mark - Configuration

- (void)applyStyles
{
    [WPStyleGuide applyPostCardStyle:self];
    [WPStyleGuide applyRestorePageLabelStyle:self.restoreLabel];
    [WPStyleGuide applyRestorePageButtonStyle:self.restoreButton];
}

- (void)configureView
{
    self.restoreLabel.text = NSLocalizedString(@"Page moved to trash.", @"A short message explaining that a page was moved to the trash bin.");
    NSString *buttonTitle = NSLocalizedString(@"Undo", @"The title of an 'undo' button. Tapping the button moves a trashed page out of the trash folder.");
    [self.restoreButton setTitle:buttonTitle forState:UIControlStateNormal];
}

- (void)configureCell:(id<WPPostContentViewProvider>)contentProvider
{
    self.contentProvider = contentProvider;
}


#pragma mark - Actions

- (IBAction)restoreAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(cell:receivedRestoreActionForProvider:)]) {
        [self.delegate cell:self receivedRestoreActionForProvider:self.contentProvider];
    }
}

@end
