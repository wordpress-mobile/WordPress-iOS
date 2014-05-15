#import "CommentView.h"

#import <AFNetworking/UIKit+AFNetworking.h>
#import "WPContentViewSubclass.h"
#import "UIImageView+Gravatar.h"
#import "NSAttributedString+HTML.h"
#import "DTCoreText.h"

const CGFloat CommentViewHeaderLabelVerticalInset = 10.0f;

@interface CommentView()

@property (nonatomic, strong) DTAttributedLabel *headerLabel;

@end

@implementation CommentView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _headerLabel = [[DTAttributedLabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width, 0.0f)];
        _headerLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _headerLabel.backgroundColor = [WPStyleGuide itsEverywhereGrey];
        _headerLabel.edgeInsets = UIEdgeInsetsMake(CommentViewHeaderLabelVerticalInset, RPVHorizontalInnerPadding, CommentViewHeaderLabelVerticalInset, RPVHorizontalInnerPadding);
        _headerLabel.numberOfLines = 0;
        [self addSubview:_headerLabel];
        
        UIView *contentView = [self viewForFullContent];
        [self addSubview:contentView];
    }
    return self;
}

- (void)configureContentView:(id<WPContentViewProvider>)contentProvider {
    [super configureContentView:contentProvider];
    
    NSString *avatarEmail = [contentProvider gravatarEmailForDisplay];
    NSURL *avatarURL = [contentProvider avatarURLForDisplay];
    UIImage *avatarPlaceholderImage = [UIImage imageNamed:@"gravatar"];
    
    // Use email if it exists, otherwise a direct URL
    if (avatarEmail) {
        [self.avatarImageView setImageWithGravatarEmail:avatarEmail fallbackImage:avatarPlaceholderImage];
    } else if (avatarURL) {
        [self.avatarImageView setImageWithURL:avatarURL placeholderImage:avatarPlaceholderImage];
    }
    
    NSString *commentHtml = [contentProvider contentForDisplay];
    if ([commentHtml length] == 0) {
        return;
    }

    NSData *data = [commentHtml dataUsingEncoding:NSUTF8StringEncoding];
    self.textContentView.attributedString = [[NSAttributedString alloc] initWithHTMLData:data
                                                                                 options:[WPStyleGuide defaultDTCoreTextOptions]
                                                                      documentAttributes:nil];
    [self.textContentView relayoutText];
}

- (void)layoutSubviews {
    if ([self.headerText length] > 0) {
        [self.headerLabel setDelegate:self];
        NSAttributedString *noteContentAttributedString = [[NSAttributedString alloc] initWithHTMLData:[self.headerText dataUsingEncoding:NSUTF8StringEncoding] options:[WPStyleGuide defaultDTCoreTextOptions] documentAttributes:nil];
        [self.headerLabel setAttributedString:noteContentAttributedString];
        
        // Calculate height of headerLabel frame
        DTCoreTextLayouter *layouter = [[DTCoreTextLayouter alloc] initWithAttributedString:noteContentAttributedString];
        CGRect maxRect = CGRectMake(0.0f, 0.0f, self.headerLabel.frame.size.width, CGFLOAT_HEIGHT_UNKNOWN);
        NSRange entireString = NSMakeRange(0, [noteContentAttributedString length]);
        DTCoreTextLayoutFrame *layoutFrame = [layouter layoutFrameWithRect:maxRect range:entireString];
        CGSize sizeNeeded = layoutFrame.frame.size;
        CGRect frame = self.headerLabel.frame;
        frame.size.height = sizeNeeded.height + (2 * CommentViewHeaderLabelVerticalInset);
        [self.headerLabel setFrame:frame];
    }
    
    [super layoutSubviews];
}

- (CGFloat)topMarginHeight {
    return _headerLabel.frame.size.height;
}

@end
