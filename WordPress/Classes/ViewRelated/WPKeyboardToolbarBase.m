#import "WPKeyboardToolbarBase.h"

#pragma mark Sizes

#define WPKT_BUTTON_WIDTH 40.0f
#define WPKT_BUTTON_HEIGHT_PORTRAIT 40.0f
#define WPKT_BUTTON_HEIGHT_LANDSCAPE 33.0f
#define WPKT_BUTTON_WIDTH_IPAD 65.0f
#define WPKT_BUTTON_HEIGHT_IPAD 65.0f

#pragma mark -

@implementation WPKeyboardToolbarBase

- (CGFloat)buttonHeight {
    return IS_IPAD ? WPKT_BUTTON_HEIGHT_IPAD : WPKT_BUTTON_HEIGHT_PORTRAIT;
}

- (CGFloat)buttonWidth {
    return IS_IPAD ? WPKT_BUTTON_WIDTH_IPAD : WPKT_BUTTON_WIDTH;
}

- (void)buttonAction:(WPKeyboardToolbarButtonItem *)sender {
    DDLogMethod();
    if (![sender.actionTag isEqualToString:@"done"]) {
        [[UIDevice currentDevice] playInputClick];
    }
    if (self.delegate) {
        [self.delegate keyboardToolbarButtonItemPressed:sender];
    }
}

- (void)buildFormatButtons {
    CGFloat x = 0.0f;
    CGFloat width = [self buttonWidth];
    CGFloat height = [self buttonHeight];
    UIColor *highlightColor = [UIColor whiteColor];
    if (_boldButton == nil) {
        self.boldButton = [WPKeyboardToolbarButtonItem button];
        [_boldButton setImageName:@"icon_format_bold" withColor:nil highlightColor:highlightColor];
        _boldButton.frame = CGRectMake(x, 0, width, height);
        x += _boldButton.frame.size.width;
        _boldButton.actionTag = @"strong";
        _boldButton.accessibilityIdentifier = @"strong";
        _boldButton.actionName = NSLocalizedString(@"bold", @"Bold text formatting in the Post Editor. This string will be used in the Undo message if the last change was adding formatting.");
        _boldButton.accessibilityLabel = NSLocalizedString(@"bold", nil);
        _boldButton.exclusiveTouch = YES;
        [_boldButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (_italicsButton == nil) {
        self.italicsButton = [WPKeyboardToolbarButtonItem button];
        [_italicsButton setImageName:@"icon_format_italic" withColor:nil highlightColor:highlightColor];
        _italicsButton.frame = CGRectMake(x, 0, width, height);
        x += _italicsButton.frame.size.width;
        _italicsButton.actionTag = @"em";
        _italicsButton.accessibilityIdentifier = @"em";
        _italicsButton.actionName = NSLocalizedString(@"italic", @"Italic text formatting in the Post Editor. This string will be used in the Undo message if the last change was adding formatting.");
        _italicsButton.accessibilityLabel = NSLocalizedString(@"italic", nil);
        [_italicsButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        _italicsButton.exclusiveTouch = YES;
    }
    if (_underlineButton == nil) {
        self.underlineButton = [WPKeyboardToolbarButtonItem button];
        [_underlineButton setImageName:@"icon_format_underline" withColor:nil highlightColor:highlightColor];
        _underlineButton.frame = CGRectMake(x, 0, width, height);
        x += _underlineButton.frame.size.width;
        _underlineButton.actionTag = @"u";
        _underlineButton.accessibilityIdentifier = @"u";
        _underlineButton.actionName = NSLocalizedString(@"underline", @"Underline text formatting in the Post Editor. This string will be used in the Undo message if the last change was adding formatting.");
        _underlineButton.accessibilityLabel = NSLocalizedString(@"underline", nil);
        [_underlineButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        _underlineButton.exclusiveTouch = YES;
    }
    if (_delButton == nil) {
        self.delButton = [WPKeyboardToolbarButtonItem button];
        [_delButton setImageName:@"icon_format_strikethrough" withColor:nil highlightColor:highlightColor];
        _delButton.frame = CGRectMake(x, 0, width, height);
        x += _delButton.frame.size.width;
        _delButton.actionTag = @"del";
        _delButton.accessibilityIdentifier = @"del";
        _delButton.actionName = NSLocalizedString(@"del", @"<del> (deleted text) HTML formatting in the Post Editor. This string will be used in the Undo message if the last change was adding a <del> HTML element.");
        _delButton.accessibilityLabel = NSLocalizedString(@"delete", nil);
        _delButton.exclusiveTouch = YES;
        [_delButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (_linkButton == nil) {
        self.linkButton = [WPKeyboardToolbarButtonItem button];
        [_linkButton setImageName:@"icon_format_link" withColor:nil highlightColor:highlightColor];
        _linkButton.frame = CGRectMake(x, 0, width, height);
        x += _linkButton.frame.size.width;
        _linkButton.actionTag = @"link";
        _linkButton.accessibilityIdentifier = @"link";
        _linkButton.actionName = NSLocalizedString(@"link", @"Link helper button in the Post Editor. This string will be used in the Undo message if the last change was adding a link.");
        _linkButton.accessibilityLabel = NSLocalizedString(@"link", nil);
        _linkButton.exclusiveTouch = YES;
        [_linkButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (_quoteButton == nil) {
        self.quoteButton = [WPKeyboardToolbarButtonItem button];
        [_quoteButton setImageName:@"icon_format_quote" withColor:nil highlightColor:highlightColor];
        _quoteButton.frame = CGRectMake(x, 0, width, height);
		x += _quoteButton.frame.size.width;
        _quoteButton.actionTag = @"blockquote";
        _quoteButton.accessibilityIdentifier = @"blockquote";
        _quoteButton.actionName = NSLocalizedString(@"quote", @"Blockquote HTML formatting in the Post Editor. This string will be used in the Undo message if the last change was adding a blockquote.");
        _quoteButton.accessibilityLabel = NSLocalizedString(@"quote", nil);
        _quoteButton.exclusiveTouch = YES;
        [_quoteButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (_moreButton == nil) {
        self.moreButton = [WPKeyboardToolbarButtonItem button];
        [_moreButton setImageName:@"icon_format_more" withColor:nil highlightColor:highlightColor];
        _moreButton.frame = CGRectMake(x, 0, width, height);
        _moreButton.actionTag = @"more";
        _moreButton.accessibilityIdentifier = @"more";
        _moreButton.actionName = NSLocalizedString(@"more", @"Adding a More excerpt cut-off in the Post Editor. This string will be used in the Undo message if the last change was adding this formatting.");
        _moreButton.accessibilityLabel = NSLocalizedString(@"more", nil);
        _moreButton.exclusiveTouch = YES;
        [_moreButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)setupFormatView {
    if (_formatView == nil) {
        CGFloat height = [self buttonHeight];
        self.formatView = [[UIView alloc] init];
        [self buildFormatButtons];
        CGFloat mainWidth = _moreButton.frame.origin.x + _moreButton.frame.size.width;
        _formatView.frame = CGRectMake(0, 0, mainWidth, height);
        _formatView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        
        [_formatView addSubview:_boldButton];
        [_formatView addSubview:_italicsButton];
        [_formatView addSubview:_underlineButton];
        [_formatView addSubview:_delButton];
        [_formatView addSubview:_linkButton];
        [_formatView addSubview:_quoteButton];
        [_formatView addSubview:_moreButton];
    }
}

- (void)setupDoneButton {
    if (_doneButton == nil) {
        CGFloat width = [self buttonWidth];
        CGFloat height = [self buttonHeight];
        UIColor *highlightColor = [UIColor whiteColor];
        CGFloat x = self.frame.size.width - width;
        self.doneButton = [WPKeyboardToolbarButtonItem button];
        [_doneButton setImageName:@"icon_format_keyboard" withColor:nil highlightColor:highlightColor];
        _doneButton.frame = CGRectMake(x, 0, width, height);
        _doneButton.actionTag = @"done";
        _doneButton.accessibilityIdentifier = @"done";
        _doneButton.exclusiveTouch = YES;
        _doneButton.accessibilityLabel = NSLocalizedString(@"Hide keyboard", nil);
        [_doneButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)setupView {
    [self setupBackground];
    [self setupFormatView];
    [self setupDoneButton];
}

- (void)layoutSubviews {
    
    CGRect doneFrame = _doneButton.frame;
    doneFrame.origin.x = self.frame.size.width - doneFrame.size.width;
    if (IS_IPHONE) {
        if (self.frame.size.height < WPKT_HEIGHT_IPHONE_PORTRAIT) {
            doneFrame.size.height = WPKT_BUTTON_HEIGHT_LANDSCAPE;
        } else {
            doneFrame.size.height = WPKT_BUTTON_HEIGHT_PORTRAIT;
        }
    }
    _doneButton.frame = doneFrame;
    if (_doneButton && _doneButton.superview == nil) {
        [self addSubview:_doneButton];
    }
    
    if (IS_IPHONE) {
        CGRect frame = _formatView.frame;
        if (self.frame.size.height < WPKT_HEIGHT_IPHONE_PORTRAIT) {
            frame.size.height = WPKT_BUTTON_HEIGHT_LANDSCAPE;
        } else {
            frame.size.height = WPKT_BUTTON_HEIGHT_PORTRAIT;
        }
        _formatView.frame = frame;
    }
    if (_formatView && _formatView.superview == nil) {
        [self addSubview:_formatView];
    }
}

- (id)init {
    self = [super init];
    if (self) {
        [self setupView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupView];
    }
    return self;
}

- (id)initDoneWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupBackground];
        [self setupDoneButton];
    }
    return self;
}

- (void)setupBackground {}

#pragma mark - UIInputViewAudioFeedback

- (BOOL)enableInputClicksWhenVisible {
    return YES;
}

@end
