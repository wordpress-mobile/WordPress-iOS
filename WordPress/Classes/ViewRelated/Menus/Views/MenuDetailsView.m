#import "MenuDetailsView.h"
#import "Menu.h"
#import "WPStyleGuide.h"
#import "UIColor+Helpers.h"
#import "WPFontManager.h"
#import "MenusActionButton.h"
#import "Menu+ViewDesign.h"
#import "Blog.h"

@import Gridicons;

@interface MenuDetailsView () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UIView *textFieldDesignView;
@property (nonatomic, weak) IBOutlet MenusActionButton *trashButton;
@property (nonatomic, weak) IBOutlet MenusActionButton *saveButton;
@property (nonatomic, strong) UIImageView *textFieldDesignIcon;
@property (nonatomic, strong) NSLayoutConstraint *textFieldDesignIconLeadingConstraint;
@property (nonatomic, copy) NSString *editingBeginningName;

@end

@implementation MenuDetailsView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setupStyling];
}

- (void)setupStyling
{
    self.backgroundColor = [UIColor clearColor];
    
    self.stackView.layoutMarginsRelativeArrangement = YES;
    self.stackView.layoutMargins = [Menu viewDefaultDesignInsets];
    self.stackView.spacing = 4.0;
    
    self.textField.text = nil;
    self.textField.placeholder = NSLocalizedString(@"Menu", @"Menus placeholder text for the name field of a menu with no name.");
    self.textField.textColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    self.textField.font = [WPFontManager systemLightFontOfSize:22.0];
    self.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.adjustsFontSizeToFitWidth = NO;
    [self.textField addTarget:self action:@selector(hideTextFieldKeyboard) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self.textField addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventEditingChanged];
    
    self.textFieldDesignView.layer.cornerRadius = MenusDesignDefaultCornerRadius;
    self.textFieldDesignView.backgroundColor = [UIColor clearColor];
    
    [self.trashButton setTitle:nil forState:UIControlStateNormal];
    self.trashButton.tintColor = [WPStyleGuide grey];
    [self.trashButton setImage:[Gridicon iconOfType:GridiconTypeTrash] forState:UIControlStateNormal];
    [self.trashButton addTarget:self action:@selector(trashButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [self updateSaveButtonTitle];
    [self.saveButton addTarget:self action:@selector(saveButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.saveButton.enabled = NO;
    
    {
        UIImage *image = [Gridicon iconOfType:GridiconTypePencil];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.tintColor = [WPStyleGuide grey];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.textFieldDesignIcon = imageView;
        
        [self.textFieldDesignView addSubview:imageView];
        
        NSLayoutConstraint *leadingConstraint = [imageView.leadingAnchor constraintEqualToAnchor:self.textField.leadingAnchor];
        self.textFieldDesignIconLeadingConstraint = leadingConstraint;
        [self updateTextFieldDesignIconPositioning];
        [NSLayoutConstraint activateConstraints:@[
                                                  [imageView.widthAnchor constraintEqualToConstant:14],
                                                  [imageView.heightAnchor constraintEqualToConstant:14],
                                                  [imageView.centerYAnchor constraintEqualToAnchor:self.textField.centerYAnchor],
                                                  leadingConstraint
                                                  ]];
    }
}

- (void)setMenu:(Menu *)menu
{
    if (_menu != menu) {
        _menu = menu;
        self.textField.text = menu.name;
        self.trashButton.hidden = menu.menuID.integerValue == MenuDefaultID;
        [self updateTextFieldDesignIconPositioning];
    }
}

- (void)setSavingEnabled:(BOOL)savingEnabled
{
    if (_savingEnabled != savingEnabled) {
        _savingEnabled = savingEnabled;
        self.saveButton.enabled = savingEnabled;
    }
}

- (void)setIsSaving:(BOOL)isSaving
{
    if (_isSaving != isSaving) {
        _isSaving = isSaving;
        self.saveButton.userInteractionEnabled = !isSaving;
        [self updateSaveButtonTitle];
    }
}

- (void)updateSaveButtonTitle
{
    if (self.isSaving) {
        [self.saveButton setTitle:NSLocalizedString(@"Saving...", @"Menus save button title while it is saving a Menu.") forState:UIControlStateNormal];
    } else {
        [self.saveButton setTitle:NSLocalizedString(@"Save", @"Menus save button title") forState:UIControlStateNormal];
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

- (void)showTextFieldEditingState:(NSTimeInterval)duration animationOptions:(UIViewAnimationOptions)options
{
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        
        self.textFieldDesignIcon.hidden = YES;
        self.textFieldDesignView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void)hideTextFieldEditingState:(NSTimeInterval)duration animationOptions:(UIViewAnimationOptions)options
{
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        
        self.textFieldDesignView.backgroundColor = [UIColor clearColor];

    } completion:^(BOOL finished) {

    }];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self updateTextFieldDesignIconPositioning];
}

- (BOOL)resignFirstResponder
{
    return [self.textField resignFirstResponder];
}

#pragma mark - buttons

- (void)saveButtonPressed
{
    [self.delegate detailsViewSelectedToSaveMenu:self];
}

- (void)trashButtonPressed
{
    [self.delegate detailsViewSelectedToDeleteMenu:self];
}

#pragma mark - delegate helpers

- (void)tellDelegateMenuNameChanged
{
    [self.delegate detailsViewUpdatedMenuName:self];
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
    [self showTextFieldEditingState:0.3 animationOptions:UIViewAnimationOptionCurveEaseOut];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // Update the textField to the set menu name if needed.
    textField.text = self.menu.name;
    
    [self updateTextFieldDesignIconPositioning];
    [UIView animateWithDuration:0.25 animations:^{
        self.textFieldDesignIcon.hidden = NO;
    }];
    
    [self hideTextFieldEditingState:0.3 animationOptions:UIViewAnimationOptionCurveEaseOut];
}

@end
