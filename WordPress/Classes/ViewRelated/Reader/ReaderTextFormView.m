#import "ReaderTextFormView.h"
#import "IOS7CorrectedTextView.h"

@interface ReaderTextFormView()

@property (nonatomic, strong) UINavigationItem *oldNavigationItem;

@end

@implementation ReaderTextFormView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		CGFloat width = frame.size.width;
		CGFloat height = frame.size.height;
		
		self.backgroundColor = [UIColor colorWithRed:47.0f/255.0f green:121.0f/255.0f blue:173.0f/255.0f alpha:1.0f];
		
		self.borderImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"note-reply-field"] resizableImageWithCapInsets:UIEdgeInsetsMake(6.0f, 6.0f, 6.0f, 6.0f)]];
		_borderImageView.frame = CGRectMake(10.0f, 10.0f, width - 20.0f, height - 20.0f);
		_borderImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubview:_borderImageView];
		
		UIFont *font = [UIFont systemFontOfSize:ReaderTextFormFontSize];
		
		self.textView = [[IOS7CorrectedTextView alloc] initWithFrame:CGRectMake(15.0f, 15.0f, width - 30.0, height - 30.0f)];
		_textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_textView.font = font;
		_textView.delegate = self;
		_textView.backgroundColor = [UIColor clearColor];
		[self addSubview:_textView];

		self.requireText = YES;
		
		self.promptLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 15.0f, width - 50.0f, 20.0f)];
		_promptLabel.backgroundColor = [UIColor clearColor];
		_promptLabel.textColor = [UIColor grayColor];
		_promptLabel.font = [UIFont systemFontOfSize:ReaderTextFormFontSize];
		[self addSubview:_promptLabel];
		
		self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		frame = _activityView.frame;
		frame.origin.x = (width / 2.0f) - (frame.size.width / 2.0f);
		frame.origin.y = (height / 2.0f) - (frame.size.height / 2.0f);
		_activityView.frame = frame;
		_activityView.hidesWhenStopped = YES;
		_activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
		
		[self addSubview:_activityView];
    }
	
    return self;
}


- (void)didMoveToWindow {
	[self updateNavItem];
}


- (NSString *)text {
	return _textView.text;
}


- (void)setText:(NSString *)text {
	_promptLabel.hidden = (_textView.isFirstResponder || [text length] > 0) ? YES : NO;
	_textView.text = text;
}


- (void)enableForm:(BOOL)enabled {

	_textView.editable = enabled;
	if (self.requireText) {
		_sendButton.enabled = (([_textView.text length] > 0) && enabled);
	} else {
		_sendButton.enabled = enabled;
	}
	
	if (enabled) {
		_textView.backgroundColor = [UIColor whiteColor];
	} else {
		_textView.backgroundColor = [UIColor lightGrayColor];
	}
}


- (void)updateNavItem {
	if (!_navigationItem) return;
	
	[self configureNavItem];

	if (!self.window) {
		self.navigationItem.titleView = self.oldNavigationItem.titleView;
		self.navigationItem.leftBarButtonItems = self.oldNavigationItem.leftBarButtonItems;
		self.navigationItem.rightBarButtonItems = self.oldNavigationItem.rightBarButtonItems;
		self.oldNavigationItem = nil;
		return;
	}

	self.navigationItem.titleView = _headerView;
    self.navigationItem.leftBarButtonItems = @[_cancelButton];
    self.navigationItem.rightBarButtonItems = @[_sendButton];
}


- (void)configureNavItem {
	
	if (!_oldNavigationItem) {
		self.oldNavigationItem = [[UINavigationItem alloc] init];
		_oldNavigationItem.titleView = self.navigationItem.titleView;
		_oldNavigationItem.leftBarButtonItems = self.navigationItem.leftBarButtonItems;
		_oldNavigationItem.rightBarButtonItems = self.navigationItem.rightBarButtonItems;
	}

	if (!_headerView) {
		CGFloat y = UIInterfaceOrientationIsPortrait([[[UIApplication sharedApplication] keyWindow] rootViewController].interfaceOrientation) ? 6.0f : 0.0f;
		self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, y, 200.0f, 32.0f)];
		_headerView.backgroundColor = [UIColor clearColor];
		_headerView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
		
		self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 200.0f, 18.0f)];
		_titleLabel.font = [UIFont boldSystemFontOfSize:16.0f];
		_titleLabel.textAlignment = NSTextAlignmentCenter;
		_titleLabel.backgroundColor = [UIColor clearColor];
		_titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _titleLabel.textColor = [UIColor whiteColor];
		[_headerView addSubview:_titleLabel];
		
		
		self.detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 18.0f, 200.0f, 14.0f)];
		_detailLabel.font = [UIFont systemFontOfSize:12.0f];
		_detailLabel.textAlignment = NSTextAlignmentCenter;
		_detailLabel.backgroundColor = [UIColor clearColor];
		_detailLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _detailLabel.textColor = [UIColor whiteColor];
		[_headerView addSubview:_detailLabel];
	}
	
	if (!_sendButton) {
		self.sendButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send", @"")
														   style:[WPStyleGuide barButtonStyleForDone]
														  target:self
														  action:@selector(handleSendButtonTapped:)];
        
        self.sendButton.enabled = [self shouldEnableSendButton];
	}
	
	if (!_cancelButton) {
		self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"")
															 style:[WPStyleGuide barButtonStyleForBordered]
															target:self
															action:@selector(handleCancelButtonTapped:)];
	}
	
}


- (void)dismiss {
	if ([_delegate respondsToSelector:@selector(readerTextFormShouldDismiss:)]) {
		[_delegate readerTextFormShouldDismiss:self];
	}
}


- (void)handleSendButtonTapped:(id)sender {
	[self endEditing:YES];
	
	if([_delegate respondsToSelector:@selector(readerTextFormWillSend:)]) {
		[_delegate readerTextFormWillSend:self];
	}
}


- (void)handleCancelButtonTapped:(id)sender {
	[self endEditing:YES];

	if([_delegate respondsToSelector:@selector(readerTextFormDidCancel:)]) {
		[_delegate readerTextFormDidCancel:self];
	}
}

- (BOOL)shouldEnableSendButton {
    return (([_textView.text length] > 0) || !_requireText);
}


#pragma mark - UITextView Delegate Methods

- (void)textViewDidBeginEditing:(UITextView *)textView {
	_promptLabel.hidden = YES;
	
	_sendButton.enabled = [self shouldEnableSendButton];
	
	if([_delegate respondsToSelector:@selector(readerTextFormDidBeginEditing:)]) {
		[_delegate readerTextFormDidBeginEditing:self];
	}
}


- (void)textViewDidChange:(UITextView *)textView {
	_sendButton.enabled = [self shouldEnableSendButton];
	
	if([_delegate respondsToSelector:@selector(readerTextFormDidChange:)]) {
		[_delegate readerTextFormDidChange:self];
	}
}


- (void)textViewDidEndEditing:(UITextView *)textView {
	_promptLabel.hidden = (_textView.text.length > 0) ? YES : NO;
	
	if([_delegate respondsToSelector:@selector(readerTextFormDidEndEditing:)]) {
		[_delegate readerTextFormDidEndEditing:self];
	}
}


@end
