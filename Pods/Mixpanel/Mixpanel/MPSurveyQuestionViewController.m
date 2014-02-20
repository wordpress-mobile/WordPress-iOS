#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <QuartzCore/QuartzCore.h>

#import "MPSurveyQuestionViewController.h"

@interface MPSurveyQuestionViewController ()

@property (nonatomic, strong) IBOutlet UILabel *prompt;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *promptHeight;

@end

@interface MPSurveyMultipleChoiceQuestionViewController : MPSurveyQuestionViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) MPSurveyMultipleChoiceQuestion *question;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *tableContainer;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *tableContainerVerticalPadding;

@end

typedef NS_ENUM(NSInteger, MPSurveyTableViewCellPosition) {
    MPSurveyTableViewCellPositionTop,
    MPSurveyTableViewCellPositionMiddle,
    MPSurveyTableViewCellPositionBottom,
    MPSurveyTableViewCellPositionSingle
};

@interface MPSurveyTableViewCellBackground : UIView

@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic) MPSurveyTableViewCellPosition position;

@end

@interface MPSurveyTableViewCell : UITableViewCell

@property(nonatomic,getter=isChecked) BOOL checked;
@property (nonatomic, strong) IBOutlet UILabel *label;
@property (nonatomic, strong) IBOutlet UILabel *selectedLabel;
@property (nonatomic, strong) IBOutlet UIImageView *checkmark;
@property (nonatomic, strong) IBOutlet MPSurveyTableViewCellBackground *customBackgroundView;
@property (nonatomic, strong) IBOutlet MPSurveyTableViewCellBackground *customSelectedBackgroundView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *selectedLabelLeadingSpace;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *checkmarkLeadingSpace;

@end

@interface MPSurveyTextQuestionViewController : MPSurveyQuestionViewController <UITextViewDelegate>

@property (nonatomic, strong) MPSurveyTextQuestion *question;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *promptTopSpace;
@property (nonatomic, strong) IBOutlet UITextView *textView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *textViewHeight;
@property (nonatomic, strong) IBOutlet UIView *keyboardAccessory;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *keyboardAccessoryWidth;
@property (nonatomic, strong) IBOutlet UILabel *charactersLeftLabel;

@end

@implementation MPSurveyQuestionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _prompt.text = self.question.prompt;
}

- (void)viewWillLayoutSubviews
{
    // Can't use _prompt.bounds here cause it hasn't been calculated yet.
    CGFloat promptWidth = self.view.bounds.size.width - 30; // 2x 15 point horizontal padding on prompt
    CGFloat promptHeight = UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? 72 : 48;
    UIFont *font = _prompt.font;
    CGSize constraintSize = CGSizeMake(promptWidth, CGFLOAT_MAX);

    // Lower prompt font size until it fits (or hits min of 9 points).
    for (CGFloat size = 20; size >= 9; size--) {
        font = [font fontWithSize:size];
        CGSize sizeToFit;

        // Use boundingRectWithSize for iOS 7 and above, sizeWithFont otherwise.
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
            sizeToFit = [_prompt.text boundingRectWithSize:constraintSize
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:@{NSFontAttributeName: font}
                                                       context:nil].size;
        } else {
            sizeToFit = [_prompt.text sizeWithFont:font
                                 constrainedToSize:constraintSize
                                     lineBreakMode:_prompt.lineBreakMode];
        }
#else
        sizeToFit = [_prompt.text sizeWithFont:font
                             constrainedToSize:constraintSize
                                 lineBreakMode:_prompt.lineBreakMode];
#endif

        if (sizeToFit.height <= promptHeight) {
            promptHeight = sizeToFit.height;
            break;
        }
    }
    _prompt.font = font;
    _promptHeight.constant = ceilf(promptHeight);
}


@end

@implementation MPSurveyTableViewCellBackground

- (void)setPosition:(MPSurveyTableViewCellPosition)position
{
    BOOL changed = _position != position;
    _position = position;
    if (changed) {
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
    UIRectCorner corners;
    if (_position == MPSurveyTableViewCellPositionTop) {
        corners = UIRectCornerTopLeft | UIRectCornerTopRight;
    } else if (_position == MPSurveyTableViewCellPositionMiddle) {
        corners = 0;
    } else if (_position == MPSurveyTableViewCellPositionBottom) {
        corners = UIRectCornerBottomLeft | UIRectCornerBottomRight;
    } else {
        // MPSurveyTableViewCellBackgroundPositionSingle
        corners = UIRectCornerAllCorners;
    }

    // pixel fitting
    rect.origin.x += 0.5;
    rect.origin.y += 0.5;
    rect.size.width -= 1;
    if (_position == MPSurveyTableViewCellPositionBottom) {
        rect.size.height -= 1;
    }

    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect
                                               byRoundingCorners:corners
                                                     cornerRadii:CGSizeMake(5, 5)];

    [path setLineCapStyle:kCGLineCapSquare];
    [_strokeColor setStroke];
    [_fillColor setFill];
    [path stroke];
    [path fill];
}

@end

@implementation MPSurveyTableViewCell

- (void)setChecked:(BOOL)checked animatedWithCompletion:(void (^)(BOOL))completion
{
    _checked = checked;
    NSTimeInterval duration = 0.25;
    if (checked) {
        [UIView animateWithDuration:duration * 0.5
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             _label.alpha = 0;
                             _customBackgroundView.alpha = 0;
                             _checkmark.alpha = 1;
                             _selectedLabel.alpha = 1;
                             _customSelectedBackgroundView.alpha = 1;
                         }
                         completion:^(BOOL finished) {
                             _checkmarkLeadingSpace.constant = 20;
                             [UIView animateWithDuration:duration * 0.5
                                                   delay:0
                                                 options:UIViewAnimationOptionCurveEaseOut
                                              animations:^{
                                                  [self.contentView layoutIfNeeded];
                                                  _selectedLabelLeadingSpace.constant = 46;
                                                  [UIView animateWithDuration:duration * 0.5 * 0.5
                                                                        delay:duration * 0.5 * 0.5
                                                                      options:0
                                                                   animations:^{
                                                                       [self.contentView layoutIfNeeded];
                                                                   }
                                                                   completion:completion];
                                              }
                                              completion:nil];
                         }];
    } else {
        _checkmarkLeadingSpace.constant = 15;
        _selectedLabelLeadingSpace.constant = 30;
        [UIView animateWithDuration:duration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             _checkmark.alpha = 0;
                             _selectedLabel.alpha = 0;
                             _customSelectedBackgroundView.alpha = 0;
                             _label.alpha = 1;
                             _customBackgroundView.alpha = 1;
                             [self.contentView layoutIfNeeded];
                         }
                         completion:completion];
    }
}

@end

@implementation MPSurveyMultipleChoiceQuestionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _tableView.contentInset = UIEdgeInsetsMake(44, 0, 44, 0);
}

- (void)viewDidLayoutSubviews
{
    CAGradientLayer *fadeLayer = [CAGradientLayer layer];
    CGColorRef outerColor = [UIColor colorWithWhite:1 alpha:0].CGColor;
    CGColorRef innerColor = [UIColor colorWithWhite:1 alpha:1].CGColor;
    fadeLayer.colors = @[(__bridge id)outerColor, (__bridge id)innerColor, (__bridge id)innerColor, (__bridge id)outerColor];
    // add 44 pixels of fade in and out at top and bottom of table view container
    CGFloat offset = 44 / _tableContainer.bounds.size.height;
    fadeLayer.locations = @[@0, @(0 + offset), @(1 - offset), @1];
    fadeLayer.bounds = _tableContainer.bounds;
    fadeLayer.anchorPoint = CGPointZero;
    _tableContainer.layer.mask = fadeLayer;
}

- (NSString *)labelForValue:(id)value
{
    NSString *label;
    if ([value isKindOfClass:[NSString class]]) {
        label = value;
    } else if ([value isKindOfClass:[NSNumber class]]) {
        int i = [value intValue];
        if (CFNumberGetType((CFNumberRef)value) == kCFNumberCharType && (i == 0 || i == 1)) {
            label = i ? @"Yes" : @"No";
        } else {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            label = [formatter stringFromNumber:value];
        }
    } else if ([value isKindOfClass:[NSNull class]]) {
        label = @"None";
    } else {
        NSLog(@"%@ unexpected value for survey choice: %@", self, value);
        label = [value description];
    }
    return label;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger)[self.question.choices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MPSurveyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MPSurveyTableViewCell"];
    NSString *text = [self labelForValue:(self.question.choices)[(NSUInteger)indexPath.row]];
    cell.label.text = text;
    cell.selectedLabel.text = text;
    UIColor *strokeColor = [UIColor colorWithWhite:1 alpha:0.5];
    cell.backgroundColor = [UIColor clearColor]; // necessary on ipad to get rid of white background in cell
    cell.customBackgroundView.strokeColor = strokeColor;
    cell.customSelectedBackgroundView.strokeColor = strokeColor;
    cell.customBackgroundView.fillColor = [UIColor clearColor];
    cell.customSelectedBackgroundView.fillColor = [self.highlightColor colorWithAlphaComponent:0.3];
    MPSurveyTableViewCellPosition position;
    if (indexPath.row == 0) {
        if ([self.question.choices count] == 1) {
            position = MPSurveyTableViewCellPositionSingle;
        } else {
            position = MPSurveyTableViewCellPositionTop;
        }
    } else if (indexPath.row == (NSInteger)([self.question.choices count] - 1)) {
        position = MPSurveyTableViewCellPositionBottom;
    } else {
        position = MPSurveyTableViewCellPositionMiddle;
    }
    cell.customBackgroundView.position = position;
    cell.customSelectedBackgroundView.position = position;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MPSurveyTableViewCell *cell = (MPSurveyTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    if (!cell.isChecked) {
        [cell setChecked:YES animatedWithCompletion:^(BOOL finished){
            id value = (self.question.choices)[(NSUInteger)indexPath.row];
            __strong id<MPSurveyQuestionViewControllerDelegate> strongDelegate = self.delegate;
            if (strongDelegate != nil) {
                [strongDelegate questionController:self didReceiveAnswerProperties:@{@"$value": value}];
            }
        }];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MPSurveyTableViewCell *cell = (MPSurveyTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    if (cell.isChecked) {
        [cell setChecked:NO animatedWithCompletion:nil];
    }
}

@end

@implementation MPSurveyTextQuestionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _textView.backgroundColor = [self.highlightColor colorWithAlphaComponent:0.3];
    _textView.delegate = self;
    _textView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.5].CGColor;
    _textView.layer.borderWidth = 1;
    _textView.layer.cornerRadius = 5;
    _textView.inputAccessoryView = _keyboardAccessory;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self registerForKeyboardNotifications];
    if (UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        [_textView becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_textView resignFirstResponder];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _keyboardAccessoryWidth.constant = self.view.bounds.size.width;
    _textViewHeight.constant = UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? 72 : 48;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    BOOL shouldChange;
    if ([text isEqualToString:@"\n"]) {
        // submit answer
        shouldChange = NO;
        __strong id<MPSurveyQuestionViewControllerDelegate> strongDelegate = self.delegate;
        if (strongDelegate != nil) {
            [strongDelegate questionController:self didReceiveAnswerProperties:@{@"$value": textView.text}];
        }
    } else {
        NSUInteger newLength = [textView.text length] + ([text length] - range.length);
        shouldChange = newLength <= 255;
        if (shouldChange) {
            [UIView animateWithDuration:0.3 animations:^{
                _charactersLeftLabel.text = [NSString stringWithFormat:@"%@ character%@ left", @(255 - newLength), (255 - newLength == 1) ? @"": @"s"];
                _charactersLeftLabel.alpha = (newLength > 155) ? 1 : 0;
            }];
        }
    }
    return shouldChange;
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)note
{
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    CGFloat promptTopSpace, promptAlpha;
    if (UIDeviceOrientationIsPortrait(([UIApplication sharedApplication].statusBarOrientation))) {
        promptTopSpace = 15;
        promptAlpha = 1;
    } else {
        promptTopSpace = -(self.prompt.bounds.size.height + 15); // +15 for text view top space
        promptAlpha = 0;
    }
    _promptTopSpace.constant = promptTopSpace;
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.prompt.alpha = promptAlpha;
                         [self.view layoutIfNeeded];
                     }
                     completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)note
{
    NSDictionary* info = [note userInfo];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [info[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    _promptTopSpace.constant = 15;
    [UIView animateWithDuration:duration
                          delay:0
                        options:curve | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.prompt.alpha = 1;
                         [self.view layoutIfNeeded];
                     }
                     completion:nil];
}

- (IBAction)hideKeyboard
{
    [_textView resignFirstResponder];
}

@end
