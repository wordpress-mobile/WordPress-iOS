#import "MenuDetailsViewController.h"
#import "Menu.h"
#import "Menu+ViewDesign.h"
#import "Blog.h"
#import "WPAppAnalytics.h"
#import <WordPressUI/UIColor+Helpers.h>
#import <WordPressShared/WPFontManager.h>
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

@import Gridicons;

static CGFloat const TextfieldDesignIconWidth = 14.0;
static CGFloat const TextfieldDesignIconHeight = 14.0;
static NSTimeInterval const TextfieldEditingAnimationDuration = 0.3;

@interface MenuDetailsViewController () <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) IBOutlet UITextField *textField;
@property (nonatomic, strong) IBOutlet UIView *textFieldDesignView;
@property (nonatomic, strong) IBOutlet UIButton *doneButton;
@property (nonatomic, strong) IBOutlet UIButton *trashButton;
@property (nonatomic, strong, readonly) UIImageView *textFieldDesignIcon;
@property (nonatomic, strong, readonly) NSLayoutConstraint *textFieldDesignIconLeadingConstraint;
@property (nonatomic, copy) NSString *editingBeginningName;

@end

@implementation MenuDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.stackView.layoutMarginsRelativeArrangement = YES;
    UIEdgeInsets margin = [Menu viewDefaultDesignInsets];
    margin.top = 0;
    margin.bottom = 0;
    self.stackView.layoutMargins = margin;
    self.stackView.spacing = 4.0;

    [self setupTextField];
    [self setupTextFieldDesignViews];
    [self setupDoneButton];
    [self setupTrashButton];

    [self updateTextFieldDesignIconPositioning];
}

- (void)setupTextField
{
    UITextField *textField = self.textField;
    textField.placeholder = NSLocalizedString(@"Menu Name", @"Menus placeholder text for the name field of a menu with no name.");
    textField.textColor = [UIColor murielText];
    textField.tintColor = [UIColor murielListIcon];
    textField.adjustsFontForContentSizeCategory = YES;
    [self updateTextFieldFont];
    [textField addTarget:self action:@selector(hideTextFieldKeyboard) forControlEvents:UIControlEventEditingDidEndOnExit];
    [textField addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventEditingChanged];
}

- (void)setupDoneButton
{
    UIButton *doneButton = self.doneButton;
    [doneButton setTitle:NSLocalizedString(@"Done", @"Menu button title for finishing editing the Menu name.") forState:UIControlStateNormal];
    [doneButton setTitleColor:[UIColor murielPrimaryDark] forState:UIControlStateNormal];
    doneButton.titleLabel.adjustsFontForContentSizeCategory = YES;
    doneButton.alpha = 0.0;
    [doneButton addTarget:self action:@selector(doneButtonPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupTrashButton
{
    UIButton *trashButton = self.trashButton;
    [trashButton setTitle:nil forState:UIControlStateNormal];
    trashButton.tintColor = [UIColor murielListIcon];
    [trashButton setImage:[Gridicon iconOfType:GridiconTypeTrash] forState:UIControlStateNormal];
    [trashButton addTarget:self action:@selector(trashButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    trashButton.backgroundColor = [UIColor clearColor];
    trashButton.adjustsImageWhenHighlighted = YES;
}

- (void)setupTextFieldDesignViews
{
    UIView *textFieldDesignView = self.textFieldDesignView;
    textFieldDesignView.layer.cornerRadius = MenusDesignDefaultCornerRadius;

    UIImage *image = [Gridicon iconOfType:GridiconTypePencil];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.tintColor = [UIColor murielListIcon];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    _textFieldDesignIcon = imageView;

    [textFieldDesignView addSubview:imageView];

    NSLayoutConstraint *leadingConstraint = [imageView.leadingAnchor constraintEqualToAnchor:self.textField.leadingAnchor];
    _textFieldDesignIconLeadingConstraint = leadingConstraint;
    [NSLayoutConstraint activateConstraints:@[
                                              [imageView.widthAnchor constraintEqualToConstant:TextfieldDesignIconWidth],
                                              [imageView.heightAnchor constraintEqualToConstant:TextfieldDesignIconHeight],
                                              [imageView.centerYAnchor constraintEqualToAnchor:self.textField.centerYAnchor],
                                              leadingConstraint
                                              ]];
}

- (void)setMenu:(Menu *)menu
{
    if (_menu != menu) {
        _menu = menu;
        if (menu) {
            self.textField.enabled = YES;
            self.textField.text = menu.name;
            self.textFieldDesignIcon.hidden = NO;
            [self updateTextFieldDesignIconPositioning];
            self.trashButton.hidden = menu.menuID.integerValue == MenuDefaultID;
        } else {
            self.textField.text = NSLocalizedString(@"No Menu Selected", @"Menus name field text when no menu is selected.");
            self.textField.enabled = NO;
            self.textFieldDesignIcon.hidden = YES;
            self.trashButton.hidden = YES;
        }
    }
}

- (void)hideTextFieldKeyboard
{
    [self.textField resignFirstResponder];
}

- (void)updateTextFieldDesignIconPositioning
{
    CGSize textSize = [self.textField.text sizeWithAttributes:@{NSFontAttributeName: self.textField.font}];
    CGRect editingRect = [self.textField textRectForBounds:self.textField.bounds];
    CGFloat leadingConstant = editingRect.origin.x + textSize.width;
    if (leadingConstant > self.textField.frame.size.width) {
        leadingConstant = self.textField.frame.size.width;
        leadingConstant += 1.0; // padding
    } else  {
        leadingConstant += 6.0; // padding
    }

    self.textFieldDesignIconLeadingConstraint.constant = ceilf(leadingConstant);
    [self.textFieldDesignIcon setNeedsLayout];
}

- (void)updateTextFieldFont
{
    self.textField.font = [UIFont systemFontOfSize:[WPStyleGuide fontSizeForTextStyle:UIFontTextStyleTitle2]
                                            weight:UIFontWeightLight];
}

- (void)showTextFieldEditingState
{
    [UIView animateWithDuration:TextfieldEditingAnimationDuration animations:^{

        self.doneButton.alpha = 1.0;
        self.textFieldDesignIcon.hidden = YES;
        self.textFieldDesignView.backgroundColor = [UIColor murielTertiaryBackground];

    } completion:nil];
}

- (void)hideTextFieldEditingState
{
    [UIView animateWithDuration:TextfieldEditingAnimationDuration animations:^{

        self.textFieldDesignView.backgroundColor = [UIColor clearColor];
        self.doneButton.alpha = 0.0;

    } completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    [self updateTextFieldFont];
    [self updateTextFieldDesignIconPositioning];
}

- (BOOL)resignFirstResponder
{
    return [self.textField resignFirstResponder];
}

#pragma mark - buttons

- (void)doneButtonPressed
{
    [self.textField resignFirstResponder];
}

- (void)trashButtonPressed
{
    [self.delegate detailsViewControllerSelectedToDeleteMenu:self];
}

#pragma mark - delegate helpers

- (void)tellDelegateMenuNameChanged
{
    [self.delegate detailsViewControllerUpdatedMenuName:self];
}

#pragma mark - UITextField

- (void)textFieldValueChanged:(UITextField *)textField
{
    if (textField.text.length) {
        // Update the Menu name.
        self.menu.name = textField.text;
    } else {
        // Restore the original menu name.
        self.menu.name = self.editingBeginningName;
        // Show it as a placeholder for now.
        textField.placeholder = self.menu.name;
    }
    [self tellDelegateMenuNameChanged];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.editingBeginningName = textField.text;
    [self showTextFieldEditingState];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // Update the textField to the set menu name if needed.
    textField.text = self.menu.name;

    [self updateTextFieldDesignIconPositioning];
    [UIView animateWithDuration:0.25 animations:^{
        self.textFieldDesignIcon.hidden = NO;
    }];

    [self hideTextFieldEditingState];
}

@end
