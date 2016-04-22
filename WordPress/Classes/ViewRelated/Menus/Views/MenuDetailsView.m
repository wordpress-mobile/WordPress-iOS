#import "MenuDetailsView.h"
#import "Menu.h"
#import "WPStyleGuide.h"
#import "UIColor+Helpers.h"
#import "WPFontManager.h"
#import "Menu+ViewDesign.h"
#import "Blog.h"

@import Gridicons;

@interface MenuDetailsView () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UIView *textFieldDesignView;
@property (nonatomic, weak) IBOutlet UIButton *trashButton;
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
    UIEdgeInsets margin = [Menu viewDefaultDesignInsets];
    margin.top = 0;
    margin.bottom = 0;
    self.stackView.layoutMargins = margin;
    self.stackView.spacing = 4.0;
    
    UITextField *textField = self.textField;
    textField.text = nil;
    textField.placeholder = NSLocalizedString(@"Menu Name", @"Menus placeholder text for the name field of a menu with no name.");
    textField.textColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    textField.font = [WPFontManager systemLightFontOfSize:22.0];
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    textField.returnKeyType = UIReturnKeyDone;
    textField.adjustsFontSizeToFitWidth = NO;
    [textField addTarget:self action:@selector(hideTextFieldKeyboard) forControlEvents:UIControlEventEditingDidEndOnExit];
    [textField addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventEditingChanged];
    
    UIView *textFieldDesignView = self.textFieldDesignView;
    textFieldDesignView.layer.cornerRadius = MenusDesignDefaultCornerRadius;
    textFieldDesignView.backgroundColor = [UIColor clearColor];
    
    UIButton *trashButton = self.trashButton;
    [trashButton setTitle:nil forState:UIControlStateNormal];
    trashButton.tintColor = [WPStyleGuide grey];
    [trashButton setImage:[Gridicon iconOfType:GridiconTypeTrash] forState:UIControlStateNormal];
    [trashButton addTarget:self action:@selector(trashButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    trashButton.backgroundColor = [UIColor clearColor];
    trashButton.adjustsImageWhenHighlighted = YES;
    
    {
        UIImage *image = [Gridicon iconOfType:GridiconTypePencil];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.tintColor = [WPStyleGuide grey];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.textFieldDesignIcon = imageView;
        
        [textFieldDesignView addSubview:imageView];
        
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
