//
//  WPKeyboardToolbar.m
//  WordPress
//
//  Created by Jorge Bernal on 8/11/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "WPKeyboardToolbarBase.h"

#pragma mark Sizes

#define WPKT_BUTTON_HEIGHT_PORTRAIT 39.0f
#define WPKT_BUTTON_HEIGHT_LANDSCAPE 34.0f
#define WPKT_BUTTON_HEIGHT_IPAD 65.0f

// Button Width is icon width + padding
#define WPKT_BUTTON_PADDING_IPAD 18.0f
#define WPKT_BUTTON_PADDING_IPHONE 10.0f

// Button margin
#define WPKT_BUTTON_MARGIN_IPHONE 4.0f
#define WPKT_BUTTON_MARGIN_IPAD 0.0f

#pragma mark -

@implementation WPKeyboardToolbarBase

- (void)buttonAction:(WPKeyboardToolbarButtonItem *)sender {
    WPFLogMethod();
    if (![sender.actionTag isEqualToString:@"done"]) {
        [[UIDevice currentDevice] playInputClick];
    }
    if (self.delegate) {
        [self.delegate keyboardToolbarButtonItemPressed:sender];
    }
}

- (void)buildMainButtons {
    CGFloat x = 4.0f;
    CGFloat padding = IS_IPAD ? WPKT_BUTTON_PADDING_IPAD : WPKT_BUTTON_PADDING_IPHONE;
    CGFloat height = IS_IPAD ? WPKT_BUTTON_HEIGHT_IPAD : WPKT_BUTTON_HEIGHT_PORTRAIT;
	CGFloat margin = IS_IPAD ? WPKT_BUTTON_MARGIN_IPAD : WPKT_BUTTON_MARGIN_IPHONE;
    if (_boldButton == nil) {
        self.boldButton = [WPKeyboardToolbarButtonItem button];
        [_boldButton setImageName:@"toolbarBold"];
        _boldButton.frame = CGRectMake(x, 0, _boldButton.imageView.image.size.width + padding, height);
        x += _boldButton.frame.size.width + margin;
        _boldButton.actionTag = @"strong";
        _boldButton.actionName = NSLocalizedString(@"bold", @"Bold text formatting in the Post Editor. This string will be used in the Undo message if the last change was adding formatting.");
        _boldButton.exclusiveTouch = YES;
        [_boldButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (_italicsButton == nil) {
        self.italicsButton = [WPKeyboardToolbarButtonItem button];
        [_italicsButton setImageName:@"toolbarItalic"];
        _italicsButton.frame = CGRectMake(x, 0, _italicsButton.imageView.image.size.width + padding, height);
        x += _italicsButton.frame.size.width + margin;
        _italicsButton.actionTag = @"em";
        _italicsButton.actionName = NSLocalizedString(@"italic", @"Italic text formatting in the Post Editor. This string will be used in the Undo message if the last change was adding formatting.");
        [_italicsButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        _italicsButton.exclusiveTouch = YES;
    }
    if (_underlineButton == nil) {
        self.underlineButton = [WPKeyboardToolbarButtonItem button];
        [_underlineButton setImageName:@"toolbarItalic"];
        _underlineButton.frame = CGRectMake(x, 0, _underlineButton.imageView.image.size.width + padding, height);
        x += _underlineButton.frame.size.width + margin;
        _underlineButton.actionTag = @"u";
        _underlineButton.actionName = NSLocalizedString(@"underline", @"Underline text formatting in the Post Editor. This string will be used in the Undo message if the last change was adding formatting.");
        [_underlineButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        _underlineButton.exclusiveTouch = YES;
    }
    if (_delButton == nil) {
        self.delButton = [WPKeyboardToolbarButtonItem button];
        [_delButton setImageName:@"toolbarDel"];
        _delButton.frame = CGRectMake(x, 0, _delButton.imageView.image.size.width + padding, height);
        x += _delButton.frame.size.width + margin;
        _delButton.actionTag = @"del";
        _delButton.actionName = NSLocalizedString(@"del", @"<del> (deleted text) HTML formatting in the Post Editor. This string will be used in the Undo message if the last change was adding a <del> HTML element.");
        _delButton.exclusiveTouch = YES;
        [_delButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (_linkButton == nil) {
        self.linkButton = [WPKeyboardToolbarButtonItem button];
        [_linkButton setImageName:@"toolbarLink"];
        _linkButton.frame = CGRectMake(x, 0, _linkButton.imageView.image.size.width + padding, height);
        x += _linkButton.frame.size.width + margin;
        _linkButton.actionTag = @"link";
        _linkButton.actionName = NSLocalizedString(@"link", @"Link helper button in the Post Editor. This string will be used in the Undo message if the last change was adding a link.");
        _linkButton.exclusiveTouch = YES;
        [_linkButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (_quoteButton == nil) {
        self.quoteButton = [WPKeyboardToolbarButtonItem button];
        [_quoteButton setImageName:@"toolbarBlockquote"];
        _quoteButton.frame = CGRectMake(x, 0, _quoteButton.imageView.image.size.width + padding, height);
		x += _quoteButton.frame.size.width + margin;
        _quoteButton.actionTag = @"blockquote";
        _quoteButton.actionName = NSLocalizedString(@"quote", @"Blockquote HTML formatting in the Post Editor. This string will be used in the Undo message if the last change was adding a blockquote.");
        _quoteButton.exclusiveTouch = YES;
        [_quoteButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (_moreButton == nil) {
        self.moreButton = [WPKeyboardToolbarButtonItem button];
        [_moreButton setImageName:@"toolbarMore"];
        _moreButton.frame = CGRectMake(x, 0, _moreButton.imageView.image.size.width + padding, height);
        _moreButton.actionTag = @"more";
        _moreButton.actionName = NSLocalizedString(@"more", @"Adding a More excerpt cut-off in the Post Editor. This string will be used in the Undo message if the last change was adding this formatting.");
        _moreButton.exclusiveTouch = YES;
        [_moreButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)buildMainView {
    if (mainView == nil) {
        CGFloat height = IS_IPAD ? WPKT_BUTTON_HEIGHT_IPAD : WPKT_BUTTON_HEIGHT_PORTRAIT;
        mainView = [[UIView alloc] init];
        [self buildMainButtons];
        CGFloat mainWidth = _moreButton.frame.origin.x + _moreButton.frame.size.width;
        mainView.frame = CGRectMake(0, 0, mainWidth, height);
        mainView.autoresizesSubviews = YES;
        
        [mainView addSubview:_boldButton];
        [mainView addSubview:_italicsButton];
        [mainView addSubview:_underlineButton];
        [mainView addSubview:_delButton];
        [mainView addSubview:_linkButton];
        [mainView addSubview:_quoteButton];
        [mainView addSubview:_moreButton];
    }
}

- (void)setupDoneButton {
    if (_doneButton == nil) {
        self.doneButton = [WPKeyboardToolbarButtonItem button];
        _doneButton.frame = CGRectMake(4, 2, 50, 39);
        [_doneButton setTitle:@"Done" forState:UIControlStateNormal];
		_doneButton.titleLabel.textAlignment = NSTextAlignmentCenter;
		//_doneButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        _doneButton.actionTag = @"done";
        [_doneButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        if (IS_IPAD) {
            _doneButton.titleLabel.font = [UIFont systemFontOfSize:22.0f];
            [_doneButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [_doneButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
            _doneButton.titleLabel.shadowOffset = CGSizeMake(0, 1.0f);
            _doneButton.titleEdgeInsets = UIEdgeInsetsMake(2, 2, 0, 0); // Needed to make the label align
        } else {
            _doneButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
            _doneButton.titleLabel.shadowColor = [UIColor darkGrayColor];
            _doneButton.titleLabel.shadowOffset = CGSizeMake(0, -1.0);
            _doneButton.contentEdgeInsets = UIEdgeInsetsMake(1, 1, 0, 0); // Needed to make the label align
            [_doneButton setBackgroundImage:[[UIImage imageNamed:@"_doneButton-ios7"] stretchableImageWithLeftCapWidth:6.0f topCapHeight:0.0f] forState:UIControlStateNormal];
            [_doneButton setBackgroundImage:[[UIImage imageNamed:@"_doneButtonHighlighted-ios7"] stretchableImageWithLeftCapWidth:6.0f topCapHeight:0.0f] forState:UIControlStateHighlighted];
        }
        [self addSubview:_doneButton];
    }
}

- (void)setupView {
    [self buildMainView];
    [self setupDoneButton];
}

- (void)layoutSubviews {
    CGRect doneFrame = _doneButton.frame;
    doneFrame.origin.x = self.frame.size.width - doneFrame.size.width - 5;
    if (IS_IPAD) {
        doneFrame.size.height = WPKT_BUTTON_HEIGHT_IPAD;
        doneFrame.size.width = WPKT_BUTTON_HEIGHT_IPAD + 14.0f;
        doneFrame.origin.x = self.frame.size.width - doneFrame.size.width - 5;
        doneFrame.origin.y = 0;
    } else {
        if (self.frame.size.height < WPKT_HEIGHT_IPHONE_PORTRAIT) {
            doneFrame.origin.y = -1;
            doneFrame.origin.x = self.frame.size.width - doneFrame.size.width - 3;
            doneFrame.size.height = WPKT_BUTTON_HEIGHT_LANDSCAPE + 2;
        } else {
            doneFrame.origin.y = 2;
            doneFrame.origin.x = self.frame.size.width - doneFrame.size.width - 5;
            doneFrame.size.height = WPKT_BUTTON_HEIGHT_PORTRAIT;
        }
    }
    _doneButton.frame = doneFrame;
    
    // Show main view
    CGRect frame = mainView.frame;
    frame.origin.x = -1;
    if (self.frame.size.height < WPKT_HEIGHT_IPHONE_PORTRAIT) {
        frame.origin.y = -1;
        frame.size.height = WPKT_BUTTON_HEIGHT_LANDSCAPE;
    }
    mainView.frame = frame;
    if (mainView.superview == nil) {
        [self addSubview:mainView];
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

#pragma mark - UIInputViewAudioFeedback

- (BOOL) enableInputClicksWhenVisible {
    return YES;
}

@end
