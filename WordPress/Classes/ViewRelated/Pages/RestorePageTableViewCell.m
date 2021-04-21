#import "RestorePageTableViewCell.h"
#import "WPStyleGuide+Pages.h"

@import Gridicons;

@interface RestorePageTableViewCell()

@property (nonatomic, strong) IBOutlet UILabel *restoreLabel;
@property (nonatomic, strong) IBOutlet UIButton *restoreButton;

@end

@implementation RestorePageTableViewCell

#pragma mark - Life Cycle

- (void)awakeFromNib {
    [super awakeFromNib];

    [self configureView];
    [self applyStyles];
}

#pragma mark - Configuration

- (void)applyStyles
{
    [WPStyleGuide applyRestorePageLabelStyle:self.restoreLabel];
    [WPStyleGuide applyRestorePageButtonStyle:self.restoreButton];
}

- (void)configureView
{
    self.restoreLabel.text = NSLocalizedString(@"Page moved to trash.", @"A short message explaining that a page was moved to the trash bin.");
    NSString *buttonTitle = NSLocalizedString(@"Undo", @"The title of an 'undo' button. Tapping the button moves a trashed page out of the trash folder.");
    [self.restoreButton setTitle:buttonTitle forState:UIControlStateNormal];
    [self.restoreButton setImage:[UIImage gridiconOfType:GridiconTypeUndo
                                                withSize:CGSizeMake(18.0, 18.0)]
                        forState:UIControlStateNormal];
}

@end
