//
//  InlineComposeView.m
//  WordPress
//


#import "InlineComposeView.h"

@interface InlineComposeView () <UITextViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *inputAccessoryView;
@property (nonatomic, strong) UITextView *proxyTextView;
@property (nonatomic, strong) NSArray *bundle;

@end

@implementation InlineComposeView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _bundle = [[NSBundle mainBundle] loadNibNamed:@"InlineComposeView" owner:self options:nil];

        _proxyTextView = [[UITextView alloc] initWithFrame:CGRectZero];

        _proxyTextView.delegate = self;

        _proxyTextView.inputAccessoryView = self.inputAccessoryView;

        [self addSubview:_proxyTextView];

    }
    return self;
}

- (void)dealloc {
    self.bundle = nil;
    self.proxyTextView.delegate = nil;
    self.proxyTextView = nil;
}

#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder {
    return [self.proxyTextView canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder {
    return [self.proxyTextView becomeFirstResponder];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    // try to make the textview in the toolbar first responder
    NSLog(@"Window? %@", self.inputAccessoryView);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
