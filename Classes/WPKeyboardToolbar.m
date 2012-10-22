//
//  WPKeyboardToolbar.m
//  WordPress
//
//  Created by Jorge Bernal on 8/11/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "WPKeyboardToolbar.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define CGColorFromRGB(rgbValue) UIColorFromRGB(rgbValue).CGColor

#pragma mark - Constants

#define kStartColor UIColorFromRGB(0xb0b7c1)
#define kEndColor UIColorFromRGB(0x9199a4)
#define kStartColorIpad UIColorFromRGB(0xb7b6bf)
#define kEndColorIpad UIColorFromRGB(0x9d9ca7)

#pragma mark Sizes

// Spacing between button groups
#define WPKT_BUTTON_SEPARATOR 6.0f

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

@implementation WPKeyboardToolbar
@synthesize delegate, doneButton;


- (CGRect)gradientFrame {
    CGRect rect = self.bounds;
    rect.origin.y += 2;
    rect.size.height -= 2;
    return rect;
}

- (void)drawTopBorder {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0f);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    if (IS_IPAD) {
        CGContextSetStrokeColorWithColor(context, CGColorFromRGB(0x404040));
    } else {
        CGContextSetStrokeColorWithColor(context, CGColorFromRGB(0x52555b));        
    }
    CGContextMoveToPoint(context, self.bounds.origin.x, self.bounds.origin.y + 0.5f);
    CGContextAddLineToPoint(context, self.bounds.size.width, self.bounds.origin.y + 0.5f);
    CGContextStrokePath(context);
    if (IS_IPAD) {
        CGContextSetStrokeColorWithColor(context, CGColorFromRGB(0xd9d9d9));
    } else {
        CGContextSetStrokeColorWithColor(context, CGColorFromRGB(0xdbdfe4));
    }
    CGContextMoveToPoint(context, self.bounds.origin.x, self.bounds.origin.y + 1.5f);
    CGContextAddLineToPoint(context, self.bounds.size.width, self.bounds.origin.y + 1.5f);
    CGContextStrokePath(context);
    CGColorSpaceRelease(colorspace);
}

- (void)drawRect:(CGRect)rect {
    [self drawTopBorder];
}

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
    if (boldButton == nil) {
        boldButton = [WPKeyboardToolbarButtonItem button];
        [boldButton setImageName:@"toolbarBold"];
        boldButton.frame = CGRectMake(x, 0, boldButton.imageView.image.size.width + padding, height);
        x += boldButton.frame.size.width + margin;
        boldButton.actionTag = @"strong";
        boldButton.actionName = NSLocalizedString(@"bold", @"Bold text formatting in the Post Editor. This string will be used in the Undo message if the last change was adding formatting.");
        [boldButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (italicsButton == nil) {
        italicsButton = [WPKeyboardToolbarButtonItem button];
        [italicsButton setImageName:@"toolbarItalic"];
        italicsButton.frame = CGRectMake(x, 0, italicsButton.imageView.image.size.width + padding, height);
        x += italicsButton.frame.size.width + margin;
        italicsButton.actionTag = @"em";
        italicsButton.actionName = NSLocalizedString(@"italic", @"Italic text formatting in the Post Editor. This string will be used in the Undo message if the last change was adding formatting.");
        [italicsButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (linkButton == nil) {
        linkButton = [WPKeyboardToolbarButtonItem button];
        [linkButton setImageName:@"toolbarLink"];
        linkButton.frame = CGRectMake(x, 0, linkButton.imageView.image.size.width + padding, height);
        x += linkButton.frame.size.width + margin;
        linkButton.actionTag = @"link";
        linkButton.actionName = NSLocalizedString(@"link", @"Link helper button in the Post Editor. This string will be used in the Undo message if the last change was adding a link.");
        [linkButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (quoteButton == nil) {
        quoteButton = [WPKeyboardToolbarButtonItem button];
        [quoteButton setImageName:@"toolbarBlockquote"];
        quoteButton.frame = CGRectMake(x, 0, quoteButton.imageView.image.size.width + padding, height);
		x += quoteButton.frame.size.width + margin;
        quoteButton.actionTag = @"blockquote";
        quoteButton.actionName = NSLocalizedString(@"quote", @"Blockquote HTML formatting in the Post Editor. This string will be used in the Undo message if the last change was adding a blockquote.");
        [quoteButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (delButton == nil) {
        delButton = [WPKeyboardToolbarButtonItem button];
        [delButton setImageName:@"toolbarDel"];
        delButton.frame = CGRectMake(x, 0, delButton.imageView.image.size.width + padding, height);
        delButton.actionTag = @"del";
        delButton.actionName = NSLocalizedString(@"del", @"<del> (deleted text) HTML formatting in the Post Editor. This string will be used in the Undo message if the last change was adding a <del> HTML element.");
        [delButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)buildExtendedButtons {
    CGFloat padding = IS_IPAD ? WPKT_BUTTON_PADDING_IPAD : WPKT_BUTTON_PADDING_IPHONE;
    CGFloat height = IS_IPAD ? WPKT_BUTTON_HEIGHT_IPAD : WPKT_BUTTON_HEIGHT_PORTRAIT;
	CGFloat margin = IS_IPAD ? WPKT_BUTTON_MARGIN_IPAD : WPKT_BUTTON_MARGIN_IPHONE;
    CGFloat x = 4.0f;
    if (ulButton == nil) {
        ulButton = [WPKeyboardToolbarButtonItem button];
        [ulButton setImageName:@"toolbarUl"];
        ulButton.frame = CGRectMake(x, 0, ulButton.imageView.image.size.width + padding, height);
        x += ulButton.frame.size.width + margin;
        ulButton.actionTag = @"ul";
        ulButton.actionName = NSLocalizedString(@"unordered list", @"Unordered list (ul) HTML formatting in the Post Editor. This string will be used in the Undo message if the last change was adding this formatting.");
        [ulButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (olButton == nil) {
        olButton = [WPKeyboardToolbarButtonItem button];
        [olButton setImageName:@"toolbarOl"];
        olButton.frame = CGRectMake(x, 0, olButton.imageView.image.size.width + padding, height);
        x += olButton.frame.size.width + margin;
        olButton.actionTag = @"ol";
        olButton.actionName = NSLocalizedString(@"ordered list", @"Ordered list (<ol>) HTML formatting in the Post Editor. This string will be used in the Undo message if the last change was adding this formatting.");
        [olButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (liButton == nil) {
        liButton = [WPKeyboardToolbarButtonItem button];
        [liButton setImageName:@"toolbarLi"];
        liButton.frame = CGRectMake(x, 0, liButton.imageView.image.size.width + padding, height);
        x += liButton.frame.size.width + margin;
        liButton.actionTag = @"li";
        liButton.actionName = NSLocalizedString(@"list item", @"List item (<li>) HTML formatting in the Post Editor. This string will be used in the Undo message if the last change was adding this formatting.");
        [liButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (codeButton == nil) {
        codeButton = [WPKeyboardToolbarButtonItem button];
        [codeButton setImageName:@"toolbarCode"];
        codeButton.frame = CGRectMake(x, 0, codeButton.imageView.image.size.width + padding, height);
        x += codeButton.frame.size.width + margin;
        codeButton.actionTag = @"code";
        codeButton.actionName = NSLocalizedString(@"code", @"Code (<code>) HTML formatting in the Post Editor. This string will be used in the Undo message if the last change was adding this formatting.");
        [codeButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (moreButton == nil) {
        moreButton = [WPKeyboardToolbarButtonItem button];
        [moreButton setImageName:@"toolbarMore"];
        moreButton.frame = CGRectMake(x, 0, moreButton.imageView.image.size.width + padding, height);
        moreButton.actionTag = @"more";
        moreButton.actionName = NSLocalizedString(@"more", @"Adding a More excerpt cut-off in the Post Editor. This string will be used in the Undo message if the last change was adding this formatting.");
        [moreButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)buildMainView {
    if (mainView == nil) {
        CGFloat height = IS_IPAD ? WPKT_BUTTON_HEIGHT_IPAD : WPKT_BUTTON_HEIGHT_PORTRAIT;
        mainView = [[UIView alloc] init];
        [self buildMainButtons];
        CGFloat mainWidth = delButton.frame.origin.x + delButton.frame.size.width;
        mainView.frame = CGRectMake(0, 0, mainWidth, height);
        mainView.autoresizesSubviews = YES;

        [mainView addSubview:boldButton];
        [mainView addSubview:italicsButton];
        [mainView addSubview:linkButton];
        [mainView addSubview:quoteButton];
        [mainView addSubview:delButton];
    }
}

- (void)buildExtendedView {
    if (extendedView == nil) {
        CGFloat height = IS_IPAD ? WPKT_BUTTON_HEIGHT_IPAD : WPKT_BUTTON_HEIGHT_PORTRAIT;
        extendedView = [[UIView alloc] init];
        [self buildExtendedButtons];
        CGFloat extendedWidth = moreButton.frame.origin.x + moreButton.frame.size.width;
        extendedView.frame = CGRectMake(0, 0, extendedWidth, height);
        [extendedView addSubview:ulButton];
        [extendedView addSubview:olButton];
        [extendedView addSubview:liButton];
        [extendedView addSubview:codeButton];
        [extendedView addSubview:moreButton];
    }
}

- (void)toggleExtendedView {
	WPFLogMethod();
    [[UIDevice currentDevice] playInputClick];        
	if (!toggleButton.selected == true) {
		[toggleButton setBackgroundImage:[UIImage imageNamed:@"toggleButtonExtended"] forState:UIControlStateNormal];
	}
	else {
		[toggleButton setBackgroundImage:[UIImage imageNamed:@"toggleButtonMain"] forState:UIControlStateNormal];
	}

    toggleButton.selected = !toggleButton.selected;
    [self setNeedsLayout];
}

- (void)buildToggleButton {
    if (toggleButton == nil) {
        toggleButton = [WPKeyboardToolbarButtonItem button];
        toggleButton.frame = CGRectMake(2, 2, 39, 39);
        toggleButton.adjustsImageWhenHighlighted = NO;
        [toggleButton addTarget:self action:@selector(toggleExtendedView) forControlEvents:UIControlEventTouchDown];
		[toggleButton setBackgroundImage:[UIImage imageNamed:@"toggleButtonMain"] forState:UIControlStateNormal];
		//[toggleButton setBackgroundImage:[UIImage imageNamed:@"doneButton"] forState:UIControlStateHighlighted];
		[toggleButton setBackgroundImage:[UIImage imageNamed:@"toggleButtonExtended"] forState:UIControlStateSelected];
		[toggleButton setBackgroundImage:[UIImage imageNamed:@"toggleButtonMain"] forState:UIControlStateSelected || UIControlStateHighlighted];
    }    
}

- (void)setupDoneButton {
    if (doneButton == nil) {
        doneButton = [WPKeyboardToolbarButtonItem button];
        doneButton.frame = CGRectMake(4, 2, 50, 39);
        [doneButton setTitle:@"Done" forState:UIControlStateNormal];
		doneButton.titleLabel.textAlignment = UITextAlignmentCenter;
		//doneButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        doneButton.actionTag = @"done";
        [doneButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        if (IS_IPAD) {
            doneButton.titleLabel.font = [UIFont systemFontOfSize:22.0f];
            [doneButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [doneButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
            doneButton.titleLabel.shadowOffset = CGSizeMake(0, 1.0f);
            doneButton.titleEdgeInsets = UIEdgeInsetsMake(2, 2, 0, 0); // Needed to make the label align
        } else {
            doneButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
            doneButton.titleLabel.shadowColor = [UIColor darkGrayColor];
            doneButton.titleLabel.shadowOffset = CGSizeMake(0, -1.0);
            doneButton.contentEdgeInsets = UIEdgeInsetsMake(1, 1, 0, 0); // Needed to make the label align
            [doneButton setBackgroundImage:[[UIImage imageNamed:@"doneButton"] stretchableImageWithLeftCapWidth:6.0f topCapHeight:0.0f] forState:UIControlStateNormal];
            [doneButton setBackgroundImage:[[UIImage imageNamed:@"doneButtonHighlighted"] stretchableImageWithLeftCapWidth:6.0f topCapHeight:0.0f] forState:UIControlStateHighlighted];
        }
        [self addSubview:doneButton];
    }
}

- (void)setupView {
    self.backgroundColor = UIColorFromRGB(0xb0b7c1);
    _gradient = [CAGradientLayer layer];
    _gradient.frame = [self gradientFrame];
    if (IS_IPAD) {
        _gradient.colors = [NSArray arrayWithObjects:(id)kStartColorIpad.CGColor, (id)kEndColorIpad.CGColor, nil];
    } else {
        _gradient.colors = [NSArray arrayWithObjects:(id)kStartColor.CGColor, (id)kEndColor.CGColor, nil];
    }
    [self.layer insertSublayer:_gradient atIndex:0];
    
    [self buildMainView];
    [self buildExtendedView];
    [self buildToggleButton];
    [self setupDoneButton];
}

- (void)layoutSubviews {
    _gradient.frame = [self gradientFrame];
    
    CGRect doneFrame = doneButton.frame;
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
    doneButton.frame = doneFrame;
    
    CGRect toggleFrame = toggleButton.frame;
    toggleFrame.size.height = WPKT_BUTTON_HEIGHT_PORTRAIT;
    toggleButton.frame = toggleFrame;
    
    if (self.frame.size.width <= 320.0f) {
        // iPhone portrait
        
        // Add toggle button
        if (toggleButton.superview == nil) {
            [self addSubview:toggleButton];
        }

        if (toggleButton.selected) {
            // Remove main view
            if (mainView.superview != nil) {
                [mainView removeFromSuperview];
            }
            
            // Show extended view
            CGRect frame = extendedView.frame;
            frame.origin.x = toggleButton.frame.origin.x + toggleButton.frame.size.width + 3;
            frame.origin.y = 2;
            frame.size.height = WPKT_BUTTON_HEIGHT_PORTRAIT;
            extendedView.frame = frame;
            if (extendedView.superview == nil) {
                [self addSubview:extendedView];
            }
        } else {
            // Remove extended view
            if (extendedView.superview != nil) {
                [extendedView removeFromSuperview];
            }
            
            // Show main view
            CGRect frame = mainView.frame;
            frame.origin.x = toggleButton.frame.origin.x + toggleButton.frame.size.width + 3;
            frame.origin.y = 2;
            frame.size.height = WPKT_BUTTON_HEIGHT_PORTRAIT;
            mainView.frame = frame;
            if (mainView.superview == nil) {
                [self addSubview:mainView];            
            }            
        }
    } else {
        // iPhone Landscape or iPad

        // Remove toggle button
        if (toggleButton.superview != nil) {
            [toggleButton removeFromSuperview];
        }
		
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
        
        frame = extendedView.frame;
        frame.origin.x = mainView.frame.origin.x + mainView.frame.size.width;
		if (IS_IPAD) frame.origin.x -= 4; // Dirty fix, but works for now
        if (self.frame.size.height < WPKT_HEIGHT_IPHONE_PORTRAIT) {
            frame.origin.y = -1;
            frame.size.height = WPKT_BUTTON_HEIGHT_LANDSCAPE;
        }
        extendedView.frame = frame;
        if (extendedView.superview == nil) {
            [self addSubview:extendedView];
        }
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
