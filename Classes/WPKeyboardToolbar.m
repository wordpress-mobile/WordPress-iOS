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
#define kStartColor UIColorFromRGB(0xb0b7c1)
#define kEndColor UIColorFromRGB(0x9199a4)

// Spacing between button groups
#define WPKT_BUTTON_SEPARATOR 6.0f

@implementation WPKeyboardToolbar
@synthesize delegate;

- (void)dealloc
{
    [_gradient release];
    [mainView release];
    [extendedView release];
    [boldButton release];
    [italicsButton release];
    [linkButton release];
    [quoteButton release];
    [delButton release];
    [ulButton release];
    [olButton release];
    [liButton release];
    [codeButton release];
    [moreButton release];
    [doneButton release];
    [toggleButton release];
    [super dealloc];
}

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
    CGContextSetStrokeColorWithColor(context, CGColorFromRGB(0x52555b));
    CGContextMoveToPoint(context, self.bounds.origin.x, self.bounds.origin.y + 0.5f);
    CGContextAddLineToPoint(context, self.bounds.size.width, self.bounds.origin.y + 0.5f);
    CGContextStrokePath(context);
    CGContextSetStrokeColorWithColor(context, CGColorFromRGB(0xdbdfe4));
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
    if (self.delegate) {
        [self.delegate keyboardToolbarButtonItemPressed:sender];
    }
}

- (void)buildMainButtons {
    CGFloat x = 0.0f;
    if (boldButton == nil) {
        boldButton = [WPKeyboardToolbarButtonItem button];
        boldButton.frame = CGRectMake(x, 0, 32, 37);
        x += 32;
        [boldButton setTitle:@"b" forState:UIControlStateNormal];
        boldButton.titleLabel.font = [UIFont boldSystemFontOfSize:17.0f];
        boldButton.actionTag = @"strong";
        boldButton.actionName = NSLocalizedString(@"bold", @"");
        [boldButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (italicsButton == nil) {
        italicsButton = [WPKeyboardToolbarButtonItem button];
        italicsButton.frame = CGRectMake(x, 0, 32, 37);
        x += 32;
        [italicsButton setTitle:@"i" forState:UIControlStateNormal];
        italicsButton.titleLabel.font = [UIFont italicSystemFontOfSize:17.0f];
        italicsButton.actionTag = @"em";
        italicsButton.actionName = NSLocalizedString(@"italic", @"");
        [italicsButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (linkButton == nil) {
        linkButton = [WPKeyboardToolbarButtonItem button];
        linkButton.frame = CGRectMake(x, 0, 41, 37);
        x += 41;
        [linkButton setTitle:@"link" forState:UIControlStateNormal];
        [linkButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        linkButton.actionTag = @"link";
        linkButton.actionName = NSLocalizedString(@"link", @"");
        [linkButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (quoteButton == nil) {
        quoteButton = [WPKeyboardToolbarButtonItem button];
        quoteButton.frame = CGRectMake(x, 0, 58, 37);
        x += 58;
        [quoteButton setTitle:@"quote" forState:UIControlStateNormal];
        quoteButton.actionTag = @"blockquote";
        quoteButton.actionName = NSLocalizedString(@"quote", @"");
        [quoteButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (delButton == nil) {
        delButton = [WPKeyboardToolbarButtonItem button];
        delButton.frame = CGRectMake(x, 0, 40, 37);
        x += 40;
        [delButton setTitle:@"del" forState:UIControlStateNormal];
        delButton.actionTag = @"del";
        delButton.actionName = NSLocalizedString(@"del", @"");
        [delButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)buildExtendedButtons {
    CGFloat x = 0.0f;
    if (ulButton == nil) {
        ulButton = [WPKeyboardToolbarButtonItem button];
        ulButton.frame = CGRectMake(x, 0, 32, 37);
        x += 32;
        [ulButton setTitle:@"ul" forState:UIControlStateNormal];
        ulButton.actionTag = @"ul";
        ulButton.actionName = NSLocalizedString(@"unordered list", @"");
        [ulButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (olButton == nil) {
        olButton = [WPKeyboardToolbarButtonItem button];
        olButton.frame = CGRectMake(x, 0, 32, 37);
        x += 32;
        [olButton setTitle:@"ol" forState:UIControlStateNormal];
        olButton.actionTag = @"ol";
        olButton.actionName = NSLocalizedString(@"ordered list", @"");
        [olButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (liButton == nil) {
        liButton = [WPKeyboardToolbarButtonItem button];
        liButton.frame = CGRectMake(x, 0, 32, 37);
        x += 32;
        [liButton setTitle:@"li" forState:UIControlStateNormal];
        liButton.actionTag = @"li";
        liButton.actionName = NSLocalizedString(@"list item", @"");
        [liButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (codeButton == nil) {
        codeButton = [WPKeyboardToolbarButtonItem button];
        codeButton.frame = CGRectMake(x, 0, 32, 37);
        x += 32;
        [codeButton setTitle:@"code" forState:UIControlStateNormal];
        codeButton.actionTag = @"code";
        codeButton.actionName = NSLocalizedString(@"code", @"");
        [codeButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    if (moreButton == nil) {
        moreButton = [WPKeyboardToolbarButtonItem button];
        moreButton.frame = CGRectMake(x, 0, 32, 37);
        x += 32;
        [moreButton setTitle:@"more" forState:UIControlStateNormal];
        moreButton.actionTag = @"more";
        moreButton.actionName = NSLocalizedString(@"more", @"");
        [moreButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)buildMainView {
    if (mainView == nil) {
        mainView = [[UIView alloc] init];
        [self buildMainButtons];
        CGFloat mainWidth = delButton.frame.origin.x + delButton.frame.size.width;
        mainView.frame = CGRectMake(0, 3, mainWidth, 37);

        [mainView addSubview:boldButton];
        [mainView addSubview:italicsButton];
        [mainView addSubview:linkButton];
        [mainView addSubview:quoteButton];
        [mainView addSubview:delButton];
    }
}

- (void)buildExtendedView {
    if (extendedView == nil) {
        extendedView = [[UIView alloc] init];
        [self buildExtendedButtons];
        CGFloat extendedWidth = moreButton.frame.origin.x + moreButton.frame.size.width;
        extendedView.frame = CGRectMake(0, 3, extendedWidth, 37);
        [extendedView addSubview:ulButton];
        [extendedView addSubview:olButton];
        [extendedView addSubview:liButton];
        [extendedView addSubview:codeButton];
        [extendedView addSubview:moreButton];
    }
}

- (void)setupView {
    self.backgroundColor = UIColorFromRGB(0xb0b7c1);
    _gradient = [CAGradientLayer layer];
    _gradient.frame = [self gradientFrame];
    _gradient.colors = [NSArray arrayWithObjects:(id)kStartColor.CGColor, (id)kEndColor.CGColor, nil];
    [self.layer insertSublayer:_gradient atIndex:0];
    [_gradient retain];
    
    [self buildMainView];
    [self buildExtendedView];
    [self addSubview:mainView];
}

- (void)layoutSubviews {
    _gradient.frame = [self gradientFrame];
    if (self.frame.size.width <= 320.0f) {
        // Remove extended view
        if (extendedView.superview != nil) {
            [extendedView removeFromSuperview];
        }

        // Add toggle button
        if (toggleButton.superview == nil) {
        }
        
        // Show main view
        CGRect frame = mainView.frame;
        frame.origin.x = 3;
        mainView.frame = frame;
        if (mainView.superview == nil) {
            [self addSubview:mainView];            
        }
    } else {
        // Remove toggle button
        if (toggleButton.superview != nil) {
            [toggleButton removeFromSuperview];
        }
        
        // Show main view
        CGRect frame = mainView.frame;
        frame.origin.x = 3;
        mainView.frame = frame;
        if (mainView.superview == nil) {
            [self addSubview:mainView];
        }
        
        frame = extendedView.frame;
        frame.origin.x = mainView.frame.origin.x + mainView.frame.size.width;
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

@end
