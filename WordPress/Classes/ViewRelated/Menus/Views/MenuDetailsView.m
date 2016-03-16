#import "MenuDetailsView.h"
#import "Menu.h"
#import "WPStyleGuide.h"
#import "UIColor+Helpers.h"
#import "WPFontManager.h"
#import "MenusActionButton.h"
#import "MenusDesign.h"

@interface MenuDetailsView () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UIView *textFieldDesignView;
@property (nonatomic, weak) IBOutlet MenusActionButton *trashButton;
@property (nonatomic, weak) IBOutlet MenusActionButton *saveButton;
@property (nonatomic, strong) UIImageView *textFieldDesignIcon;
@property (nonatomic, strong) NSLayoutConstraint *textFieldDesignIconLeadingConstraint;

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
    self.stackView.layoutMargins = MenusDesignDefaultInsets();
    
    self.textField.text = nil;
    self.textField.textColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    self.textField.font = [WPFontManager systemLightFontOfSize:22.0];
    self.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.adjustsFontSizeToFitWidth = NO;
    [self.textField addTarget:self action:@selector(hideTextFieldKeyboard) forControlEvents:UIControlEventEditingDidEndOnExit];
    
    self.textFieldDesignView.layer.cornerRadius = MenusDesignDefaultCornerRadius;
    self.textFieldDesignView.backgroundColor = [UIColor clearColor];
    
    self.trashButton.fillColor = [UIColor whiteColor];
    [self.trashButton setImage:[self.trashButton templatedIconImageNamed:@"icon-menus-trash"] forState:UIControlStateNormal];
    
    self.saveButton.fillColor = [WPStyleGuide mediumBlue];
    [self.saveButton setTitle:NSLocalizedString(@"Save", @"Menus save button title") forState:UIControlStateNormal];
    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    {
        UIImage *image = [[UIImage imageNamed:@"icon-menus-edit"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.tintColor = [WPStyleGuide darkBlue];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.textFieldDesignIcon = imageView;
        
        [self.textFieldDesignView addSubview:imageView];
        
        NSLayoutConstraint *leadingConstraint = [imageView.leadingAnchor constraintEqualToAnchor:self.textField.leadingAnchor];
        self.textFieldDesignIconLeadingConstraint = leadingConstraint;
        [self updateTextFieldDesignIconPositioning];
        [NSLayoutConstraint activateConstraints:@[
                                                  [imageView.widthAnchor constraintEqualToConstant:12],
                                                  [imageView.heightAnchor constraintEqualToConstant:12],
                                                  [imageView.centerYAnchor constraintEqualToAnchor:self.textField.centerYAnchor],
                                                  leadingConstraint
                                                  ]];
    }
}

- (void)setMenu:(Menu *)menu
{
    if (_menu != menu) {
        _menu = menu;
        self.textField.text = self.menu.name;
        [self updateTextFieldDesignIconPositioning];
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

#pragma mark - delegate helpers

- (void)tellDelegateMenuNameChanged
{
    [self.delegate detailsViewUpdatedMenuName:self];
}

#pragma mark - UITextField

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self showTextFieldEditingState:0.3 animationOptions:UIViewAnimationOptionCurveEaseOut];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (!textField.text.length) {
        // restore the original name if the user cleared the text
        textField.text = self.menu.name;
    }
    
    // update the menu CoreData object
    self.menu.name = textField.text;
    [self tellDelegateMenuNameChanged];
    
    [self updateTextFieldDesignIconPositioning];
    [UIView animateWithDuration:0.25 animations:^{
        self.textFieldDesignIcon.hidden = NO;
    }];
    
    [self hideTextFieldEditingState:0.3 animationOptions:UIViewAnimationOptionCurveEaseOut];
}

@end
