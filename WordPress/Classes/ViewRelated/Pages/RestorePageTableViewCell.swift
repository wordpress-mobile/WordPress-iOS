import Foundation

//@interface RestorePageTableViewCell()

class RestorePageTableViewCell: BasePageListCell {

//@property (nonatomic, strong) IBOutlet UILabel *restoreLabel;
//@property (nonatomic, strong) IBOutlet UIButton *restoreButton;

    @IBOutlet private var restoreLabel: UILabel!
    @IBOutlet private var restoreButton: UIButton!

//@end
//
//@implementation RestorePageTableViewCell
//
//#pragma mark - Life Cycle
//
//- (void)awakeFromNib {
//    [super awakeFromNib];
//
//    [self configureView];
//    [self applyStyles];
//}
    override func awakeFromNib() {
        super.awakeFromNib()

        configureView()
        applyStyles()
    }

//#pragma mark - Configuration
//
//- (void)applyStyles
//{
//    [WPStyleGuide applyRestorePageLabelStyle:self.restoreLabel];
//    [WPStyleGuide applyRestorePageButtonStyle:self.restoreButton];
//}
    private func applyStyles() {
        WPStyleGuide.applyRestorePageLabelStyle(restoreLabel)
        WPStyleGuide.applyRestorePageButtonStyle(restoreButton)
    }

//- (void)configureView
//{
//    self.restoreLabel.text = NSLocalizedString(@"Page moved to trash.", @"A short message explaining that a page was moved to the trash bin.");
//    NSString *buttonTitle = NSLocalizedString(@"Undo", @"The title of an 'undo' button. Tapping the button moves a trashed page out of the trash folder.");
//    [self.restoreButton setTitle:buttonTitle forState:UIControlStateNormal];
//}
    private func configureView() {
        restoreLabel.text = NSLocalizedString("Page moved to trash.", comment: "A short message explaining that a page was moved to the trash bin.")

        let buttonTitle = NSLocalizedString("Undo", comment: "The title of an 'undo' button. Tapping the button moves a trashed page out of the trash folder.")

        restoreButton.setTitle(buttonTitle, for: .normal)
    }

//@end
}
