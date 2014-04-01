//
//  NotificationsBigBadgeViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 3/28/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "NotificationsBigBadgeViewController.h"
#import <DTCoreText/DTCoreText.h>
#import "WPWebViewController.h"

@interface NotificationsBigBadgeViewController() <DTAttributedTextContentViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *badgeImageView;
@property (nonatomic, strong) DTAttributedLabel *noteLabel;

@property Note *note;

@end

@implementation NotificationsBigBadgeViewController

- (id)initWithNote:(Note *)note {
    self = [super init];
    if (self) {
        _note = note;
        if (_note)
            self.title = note.titleForDisplay;
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _scrollView = [[UIScrollView alloc] init];
    [_scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_scrollView setScrollEnabled:YES];
    self.view.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    
    // Create badge view
    _badgeImageView = [[UIImageView alloc] init];
    [_badgeImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_badgeImageView setContentMode: UIViewContentModeScaleAspectFit];
    [_scrollView addSubview:_badgeImageView];
    
    // Set icon URL and start a wee animation to catch the eye
    NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:_note.icon]];
    __weak UIImageView *badgeImageView_ = _badgeImageView;
    [_badgeImageView setImageWithURLRequest:urlRequest
                           placeholderImage:nil
                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                        [badgeImageView_ setImage: image];
                                        badgeImageView_.transform = CGAffineTransformMakeScale(0.0,0.0);
                                        [UIView animateWithDuration:0.5f
                                                              delay:0.2f
                                             usingSpringWithDamping:0.7f
                                              initialSpringVelocity:0.5f
                                                            options:nil
                                                         animations:^{
                                                             badgeImageView_.transform = CGAffineTransformMakeScale(1.0,1.0);
                                                         }
                                                         completion:nil
                                         ];
                                    }
                                    failure:nil
     ];
    
    // Set note label from HTML content
    _noteLabel = [[DTAttributedLabel alloc] initWithFrame:CGRectMake(0.0, 0.0, IS_IPAD ? 480.0f : 320.0f, 0.0f)];
    [_noteLabel setClipsToBounds:NO];
    [_noteLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_noteLabel setLayoutFrameHeightIsConstrainedByBounds:NO];
    [_noteLabel setDelegate:self];
    [_noteLabel setBackgroundColor:[UIColor clearColor]];
    [_noteLabel setEdgeInsets:UIEdgeInsetsMake(0.0f, 20.0f, 0.0f, 20.0f)];
    [_noteLabel setNumberOfLines:0];
    
    [_scrollView addSubview:_noteLabel];
    
    NSString *noteBody = _note.bodyHtml;
    if (!noteBody)
        noteBody = _note.titleForDisplay;
    NSAttributedString *noteContentAttributedString = [[NSAttributedString alloc] initWithHTMLData:[noteBody dataUsingEncoding:NSUTF8StringEncoding] options:[WPStyleGuide defaultDTCoreTextOptions] documentAttributes:nil];
    [_noteLabel setAttributedString:noteContentAttributedString];
    
    // Adjust height of noteLabel to match height of text content
    DTCoreTextLayouter *layouter = [[DTCoreTextLayouter alloc] initWithAttributedString:noteContentAttributedString];
    CGRect maxRect = CGRectMake(0.0f, 0.0f, _noteLabel.frame.size.width, CGFLOAT_HEIGHT_UNKNOWN);
    NSRange entireString = NSMakeRange(0, [noteContentAttributedString length]);
    DTCoreTextLayoutFrame *layoutFrame = [layouter layoutFrameWithRect:maxRect range:entireString];
    CGSize sizeNeeded = [layoutFrame frame].size;
    CGRect frame = _noteLabel.frame;
    frame.size.height = sizeNeeded.height;
    _noteLabel.frame = frame;
    
    [self.view addSubview:_scrollView];
    
    [self addLayoutConstraints];
}

/**
 * Add layout constraints to position views 
 */
- (void)addLayoutConstraints {
    // Match scrollView dimensions to the main view
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_scrollView, _badgeImageView, _noteLabel);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_scrollView]|" options:0 metrics:0 views:viewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_scrollView]|" options:0 metrics:0 views:viewsDictionary]];
    
    NSNumber *badgeSize = [NSNumber numberWithInt:128];
    NSNumber *marginSize = [NSNumber numberWithInt:20];;
    NSDictionary *metricsDictionary = @{
                                        @"badgeSize" : badgeSize,
                                        @"marginSize" : marginSize
                                        };
    [_scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=marginSize)-[_badgeImageView(==badgeSize)]-marginSize-[_noteLabel]|" options:0 metrics:metricsDictionary views:viewsDictionary]];
    
    [_scrollView addConstraint:[NSLayoutConstraint constraintWithItem:_noteLabel
                                                            attribute:NSLayoutAttributeBottom
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:_scrollView
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1.0
                                                             constant:0]];
    
    // Center badge image view
    [_scrollView addConstraint:[NSLayoutConstraint constraintWithItem:_badgeImageView
                                                            attribute:NSLayoutAttributeCenterX
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:_scrollView
                                                            attribute:NSLayoutAttributeCenterX
                                                           multiplier:1.0
                                                             constant:0.0]];
    
    // Calculate how far to bring the y coordinate up in order to center both the badge and note label
    int badgeHeight = badgeSize.intValue / 2 - marginSize.intValue;
    int yPositionAdjustment = (badgeHeight + _noteLabel.frame.size.height) / 2;
    
    [_scrollView addConstraint:[NSLayoutConstraint constraintWithItem:_badgeImageView
                                                            attribute:NSLayoutAttributeCenterY
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:_scrollView
                                                            attribute:NSLayoutAttributeCenterY
                                                           multiplier:1.0
                                                             constant:-yPositionAdjustment]];
    
    // Center note label
    [_scrollView addConstraint:[NSLayoutConstraint constraintWithItem:_noteLabel
                                                            attribute:NSLayoutAttributeCenterX
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:_scrollView
                                                            attribute:NSLayoutAttributeCenterX
                                                           multiplier:1.0
                                                             constant:0.0]];
}

- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttributedString:(NSAttributedString *)string frame:(CGRect)frame {
	NSDictionary *attributes = [string attributesAtIndex:0 effectiveRange:nil];
    
	NSURL *URL = [attributes objectForKey:DTLinkAttribute];
	NSString *identifier = [attributes objectForKey:DTGUIDAttribute];
    
	DTLinkButton *button = [[DTLinkButton alloc] initWithFrame:frame];
	button.URL = URL;
	button.minimumHitSize = CGSizeMake(25, 25); // adjusts it's bounds so that button is always large enough
	button.GUID = identifier;
    
	// get image with normal link text
	UIImage *normalImage = [attributedTextContentView contentImageWithBounds:frame options:DTCoreTextLayoutFrameDrawingDefault];
	[button setImage:normalImage forState:UIControlStateNormal];
    
	// get image for highlighted link text
	UIImage *highlightImage = [attributedTextContentView contentImageWithBounds:frame options:DTCoreTextLayoutFrameDrawingDrawLinksHighlighted];
	[button setImage:highlightImage forState:UIControlStateHighlighted];
    
	// use normal push action for opening URL
	[button addTarget:self action:@selector(linkAction:) forControlEvents:UIControlEventTouchUpInside];
    
	return button;
}

- (void)linkAction:(id)sender {
    if (![sender isKindOfClass:[DTLinkButton class]])
        return;
    DTLinkButton *button = (DTLinkButton *)sender;
    WPWebViewController *webViewController = [[WPWebViewController alloc] init];
    webViewController.url = button.URL;
    
    [self.navigationController pushViewController:webViewController animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
