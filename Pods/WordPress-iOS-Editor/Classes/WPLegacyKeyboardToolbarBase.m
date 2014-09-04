#import "WPLegacyKeyboardToolbarBase.h"

#pragma mark Sizes

#define WPKT_BUTTON_WIDTH 40.0f
#define WPKT_BUTTON_HEIGHT_PORTRAIT 40.0f
#define WPKT_BUTTON_HEIGHT_LANDSCAPE 33.0f
#define WPKT_BUTTON_WIDTH_IPAD 65.0f
#define WPKT_BUTTON_HEIGHT_IPAD 65.0f

#pragma mark -

@implementation WPLegacyKeyboardToolbarBase

- (CGFloat)buttonHeight {
    return IS_IPAD ? WPKT_BUTTON_HEIGHT_IPAD : WPKT_BUTTON_HEIGHT_PORTRAIT;
}

- (CGFloat)buttonWidth {
    return IS_IPAD ? WPKT_BUTTON_WIDTH_IPAD : WPKT_BUTTON_WIDTH;
}

- (void)buttonAction:(WPLegacyKeyboardToolbarButtonItem *)sender {
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
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
    if (self.boldButton == nil) {
        self.boldButton = [WPLegacyKeyboardToolbarButtonItem button];
        [self.boldButton setImageName:@"icon_format_bold" withColor:nil highlightColor:highlightColor];
        self.boldButton.frame = CGRectMake(x, 0, width, height);
        x += self.boldButton.frame.size.width;
        self.boldButton.actionTag = @"strong";
        self.boldButton.accessibilityIdentifier = @"strong";
        self.boldButton.actionName = NSLocalizedString(@"bold", @"Bold text formatting in the Post Editor. This string will be used in the Undo message if the last change was adding formatting.");
        self.boldButton.accessibilityLabel = NSLocalizedString(@"bold", nil);
        self.boldButton.exclusiveTouch = YES;
        [self.boldButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (self.italicsButton == nil) {
        self.italicsButton = [WPLegacyKeyboardToolbarButtonItem button];
        [self.italicsButton setImageName:@"icon_format_italic" withColor:nil highlightColor:highlightColor];
        self.italicsButton.frame = CGRectMake(x, 0, width, height);
        x += self.italicsButton.frame.size.width;
        self.italicsButton.actionTag = @"em";
        self.italicsButton.accessibilityIdentifier = @"em";
        self.italicsButton.actionName = NSLocalizedString(@"italic", @"Italic text formatting in the Post Editor. This string will be used in the Undo message if the last change was adding formatting.");
        self.italicsButton.accessibilityLabel = NSLocalizedString(@"italic", nil);
        [self.italicsButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        self.italicsButton.exclusiveTouch = YES;
    }
    if (self.underlineButton == nil) {
        self.underlineButton = [WPLegacyKeyboardToolbarButtonItem button];
        [self.underlineButton setImageName:@"icon_format_underline" withColor:nil highlightColor:highlightColor];
        self.underlineButton.frame = CGRectMake(x, 0, width, height);
        x += self.underlineButton.frame.size.width;
        self.underlineButton.actionTag = @"u";
        self.underlineButton.accessibilityIdentifier = @"u";
        self.underlineButton.actionName = NSLocalizedString(@"underline", @"Underline text formatting in the Post Editor. This string will be used in the Undo message if the last change was adding formatting.");
        self.underlineButton.accessibilityLabel = NSLocalizedString(@"underline", nil);
        [self.underlineButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        self.underlineButton.exclusiveTouch = YES;
    }
    if (self.delButton == nil) {
        self.delButton = [WPLegacyKeyboardToolbarButtonItem button];
        [self.delButton setImageName:@"icon_format_strikethrough" withColor:nil highlightColor:highlightColor];
        self.delButton.frame = CGRectMake(x, 0, width, height);
        x += self.delButton.frame.size.width;
        self.delButton.actionTag = @"del";
        self.delButton.accessibilityIdentifier = @"del";
        self.delButton.actionName = NSLocalizedString(@"del", @"<del> (deleted text) HTML formatting in the Post Editor. This string will be used in the Undo message if the last change was adding a <del> HTML element.");
        self.delButton.accessibilityLabel = NSLocalizedString(@"delete", nil);
        self.delButton.exclusiveTouch = YES;
        [self.delButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (self.linkButton == nil) {
        self.linkButton = [WPLegacyKeyboardToolbarButtonItem button];
        [self.linkButton setImageName:@"icon_format_link" withColor:nil highlightColor:highlightColor];
        self.linkButton.frame = CGRectMake(x, 0, width, height);
        x += self.linkButton.frame.size.width;
        self.linkButton.actionTag = @"link";
        self.linkButton.accessibilityIdentifier = @"link";
        self.linkButton.actionName = NSLocalizedString(@"link", @"Link helper button in the Post Editor. This string will be used in the Undo message if the last change was adding a link.");
        self.linkButton.accessibilityLabel = NSLocalizedString(@"link", nil);
        self.linkButton.exclusiveTouch = YES;
        [self.linkButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (self.quoteButton == nil) {
        self.quoteButton = [WPLegacyKeyboardToolbarButtonItem button];
        [self.quoteButton setImageName:@"icon_format_quote" withColor:nil highlightColor:highlightColor];
        self.quoteButton.frame = CGRectMake(x, 0, width, height);
		x += self.quoteButton.frame.size.width;
        self.quoteButton.actionTag = @"blockquote";
        self.quoteButton.accessibilityIdentifier = @"blockquote";
        self.quoteButton.actionName = NSLocalizedString(@"quote", @"Blockquote HTML formatting in the Post Editor. This string will be used in the Undo message if the last change was adding a blockquote.");
        self.quoteButton.accessibilityLabel = NSLocalizedString(@"quote", nil);
        self.quoteButton.exclusiveTouch = YES;
        [self.quoteButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (self.moreButton == nil) {
        self.moreButton = [WPLegacyKeyboardToolbarButtonItem button];
        [self.moreButton setImageName:@"icon_format_more" withColor:nil highlightColor:highlightColor];
        self.moreButton.frame = CGRectMake(x, 0, width, height);
        self.moreButton.actionTag = @"more";
        self.moreButton.accessibilityIdentifier = @"more";
        self.moreButton.actionName = NSLocalizedString(@"more", @"Adding a More excerpt cut-off in the Post Editor. This string will be used in the Undo message if the last change was adding this formatting.");
        self.moreButton.accessibilityLabel = NSLocalizedString(@"more", nil);
        self.moreButton.exclusiveTouch = YES;
        [self.moreButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)setupFormatView {
    if (self.formatView == nil) {
        CGFloat height = [self buttonHeight];
        self.formatView = [[UIView alloc] init];
        [self buildFormatButtons];
        CGFloat mainWidth = self.moreButton.frame.origin.x + self.moreButton.frame.size.width;
        self.formatView.frame = CGRectMake(0, 0, mainWidth, height);
        self.formatView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        
        [self.formatView addSubview:self.boldButton];
        [self.formatView addSubview:self.italicsButton];
        [self.formatView addSubview:self.underlineButton];
        [self.formatView addSubview:self.delButton];
        [self.formatView addSubview:self.linkButton];
        [self.formatView addSubview:self.quoteButton];
        [self.formatView addSubview:self.moreButton];
    }
}

- (void)setupDoneButton {
    if (self.doneButton == nil) {
        CGFloat width = [self buttonWidth];
        CGFloat height = [self buttonHeight];
        UIColor *highlightColor = [UIColor whiteColor];
        CGFloat x = self.frame.size.width - width;
        self.doneButton = [WPLegacyKeyboardToolbarButtonItem button];
        [self.doneButton setImageName:@"icon_format_keyboard" withColor:nil highlightColor:highlightColor];
        self.doneButton.frame = CGRectMake(x, 0, width, height);
        self.doneButton.actionTag = @"done";
        self.doneButton.accessibilityIdentifier = @"done";
        self.doneButton.exclusiveTouch = YES;
        self.doneButton.accessibilityLabel = NSLocalizedString(@"Hide keyboard", nil);
        [self.doneButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)setupView {
    [self setupBackground];
    [self setupFormatView];
    [self setupDoneButton];
}

- (void)layoutSubviews {
    
    CGRect doneFrame = self.doneButton.frame;
    doneFrame.origin.x = self.frame.size.width - doneFrame.size.width;
    if (IS_IPHONE) {
        if (self.frame.size.height < WPKT_HEIGHT_IPHONE_PORTRAIT) {
            doneFrame.size.height = WPKT_BUTTON_HEIGHT_LANDSCAPE;
        } else {
            doneFrame.size.height = WPKT_BUTTON_HEIGHT_PORTRAIT;
        }
    }
    self.doneButton.frame = doneFrame;
    if (self.doneButton && self.doneButton.superview == nil) {
        [self addSubview:self.doneButton];
    }
    
    if (IS_IPHONE) {
        CGRect frame = self.formatView.frame;
        if (self.frame.size.height < WPKT_HEIGHT_IPHONE_PORTRAIT) {
            frame.size.height = WPKT_BUTTON_HEIGHT_LANDSCAPE;
        } else {
            frame.size.height = WPKT_BUTTON_HEIGHT_PORTRAIT;
        }
        self.formatView.frame = frame;
    }
    if (self.formatView && self.formatView.superview == nil) {
        [self addSubview:self.formatView];
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
