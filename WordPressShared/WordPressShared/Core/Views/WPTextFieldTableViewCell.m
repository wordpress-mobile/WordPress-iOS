#import "WPTextFieldTableViewCell.h"
#import "WPDeviceIdentification.h"

CGFloat const TextFieldPadding = 15.0f;

@interface WPCellTextField : UITextField
@property (nonatomic, assign) UIEdgeInsets textMargins;
@end

@interface WPTextFieldTableViewCell () <UITextFieldDelegate>

@end

@implementation WPTextFieldTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {

        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryType = UITableViewCellAccessoryNone;

		[self setupTextField];
    }
    
    return self;
}

- (void)setupTextField
{
	// Use a custom textField, see below for implementation of WPCellTextField.
	WPCellTextField *textField = [[WPCellTextField alloc] init];
	textField.translatesAutoresizingMaskIntoConstraints = NO;
	textField.adjustsFontSizeToFitWidth = YES;
	textField.textColor = [UIColor blackColor];
	textField.backgroundColor = [UIColor clearColor];
	textField.autocorrectionType = UITextAutocorrectionTypeNo;
	textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	textField.textAlignment = NSTextAlignmentLeft;
	textField.clearButtonMode = UITextFieldViewModeNever;
	textField.enabled = YES;
	textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	textField.delegate = self;

	[self.contentView addSubview:textField];
	UILayoutGuide *layoutGuide = self.contentView.readableContentGuide;
	[NSLayoutConstraint activateConstraints:@[
											  [textField.leadingAnchor constraintEqualToAnchor:layoutGuide.leadingAnchor],
											  [textField.trailingAnchor constraintEqualToAnchor:layoutGuide.trailingAnchor],
											  [textField.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
											  [textField.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
											  ]];
	_textField = textField;
}

- (void)layoutSubviews
{
	[super layoutSubviews];


	UIEdgeInsets textMargins = UIEdgeInsetsZero;
	CGSize labelSize = [self.textLabel.text sizeWithAttributes:@{NSFontAttributeName:self.textLabel.font}];
	textMargins.left = ceilf(labelSize.width) + TextFieldPadding;
	WPCellTextField *textField = (WPCellTextField *)self.textField;
	textField.textMargins = textMargins;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.textField becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.shouldDismissOnReturn) {
        [self.textField resignFirstResponder];
    } else {
        if (self.delegate) {
            [self.delegate cellWantsToSelectNextField:self];
        }
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cellTextDidChange:)]) {
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.delegate cellTextDidChange:self];
        });
    }
    return YES;
}

- (void)setShouldDismissOnReturn:(BOOL)shouldDismissOnReturn {
    _shouldDismissOnReturn = shouldDismissOnReturn;
    if (shouldDismissOnReturn) {
        self.textField.returnKeyType = UIReturnKeyDone;
    } else {
        self.textField.returnKeyType = UIReturnKeyNext;
    }
}

@end

@implementation WPCellTextField

/*
 * The textField's leading edge needs to follow the trailing edge of the textLabel
 * but the cell's textLabel layout runs the full width of the cell's contentView...
 * So instead we apply given margins to the textField's textRect and editingRect to
 * inset the text along the given margin, which currently is the textLabel's text width.
 * Brent C. Jul/13/2016
 */

- (void)setTextMargins:(UIEdgeInsets)textMargins
{
	_textMargins = textMargins;
	[self setNeedsDisplay];
}

- (CGRect)textRectWithMargins:(CGRect)rect
{
	UIEdgeInsets margins = self.textMargins;
	rect.origin.x += margins.left;
	rect.origin.y += margins.top;
	rect.size.width -= margins.left + margins.right;
	rect.size.height -= margins.top + margins.bottom;
	return rect;
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
	CGRect rect = [super textRectForBounds:bounds];
	return [self textRectWithMargins:rect];
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
	CGRect rect = [super editingRectForBounds:bounds];
	return [self textRectWithMargins:rect];
}

@end
