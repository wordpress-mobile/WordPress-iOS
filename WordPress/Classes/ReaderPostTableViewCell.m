//
//  ReaderPostTableViewCell.m
//  WordPress
//
//  Created by Eric J on 4/4/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderPostTableViewCell.h"
#import "WordPressAppDelegate.h"
#import "ReaderPost.h"
#import "ReaderPostView.h"

const CGFloat RPTVCHorizontalOuterPadding = 8.0f;
const CGFloat RPTVCVerticalOuterPadding = 16.0f;

@interface ReaderPostTableViewCell()
@property (nonatomic, strong) UIView *sideBorderView;
@end

@implementation ReaderPostTableViewCell {
}

+ (CGFloat)cellHeightForPost:(ReaderPost *)post withWidth:(CGFloat)width {
    // iPhone has extra padding around each cell
    if (IS_IPHONE) {
        width = width - 2 * RPTVCHorizontalOuterPadding;
    }
    
	CGFloat desiredHeight = [ReaderPostView heightForPost:post withWidth:width showFullContent:NO];

	return ceil(desiredHeight);
}

+ (ReaderPostTableViewCell *)cellForSubview:(UIView *)subview {
    UIView *view = subview;
	while (![view isKindOfClass:self]) {
		view = (UIView *)view.superview;
	}
    
    if (view == subview)
        return nil;
    
    return (ReaderPostTableViewCell *)view;
}


#pragma mark - Lifecycle Methods

- (void)dealloc {
	self.post = nil;
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {        
        self.sideBorderView = [[UIView alloc] init];
        self.sideBorderView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.f];
		self.sideBorderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:self.sideBorderView];

        self.postView = [[ReaderPostView alloc] initWithFrame:self.frame showFullContent:NO];
        self.postView.backgroundColor = [UIColor whiteColor];
        self.backgroundColor = [WPStyleGuide itsEverywhereGrey];

        [self.contentView addSubview:self.postView];
    }
	
    return self;
}

- (void)setHighlightedEffect:(BOOL)highlighted animated:(BOOL)animated {
    [UIView animateWithDuration:animated ? .1f : 0.f
                          delay:0
                        options:UIViewAnimationCurveEaseInOut
                     animations:^{
                         self.sideBorderView.hidden = highlighted;
                         self.alpha = highlighted ? .7f : 1.f;
                         if (highlighted) {
                             CGFloat perspective = IS_IPAD ? -0.00005 : -0.0001;
                             CATransform3D transform = CATransform3DIdentity;
                             transform.m24 = perspective;
                             transform = CATransform3DScale(transform, .98f, .98f, 1);
                             self.contentView.layer.transform = transform;
                             self.contentView.layer.shouldRasterize = YES;
                             self.contentView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
                         } else {
                             self.contentView.layer.shouldRasterize = NO;
                             self.contentView.layer.transform = CATransform3DIdentity;
                         }
                     } completion:nil];
}

- (void)setPost:(ReaderPost *)post {
	if ([post isEqual:_post])
		return;
    
    self.postView.post = post;
	_post = post;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    BOOL previouslyHighlighted = self.highlighted;
    [super setHighlighted:highlighted animated:animated];

    if (previouslyHighlighted == highlighted)
        return;

    if (highlighted) {
        [self setHighlightedEffect:highlighted animated:animated];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.selected) {
                [self setHighlightedEffect:highlighted animated:animated];
            }
        });
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    [self setHighlightedEffect:selected animated:animated];
}


- (void)prepareForReuse {
	[super prepareForReuse];
    
    [self.postView reset];
    [self setHighlightedEffect:NO animated:NO];
}


#pragma mark - Instance Methods

- (void)layoutSubviews {
	[super layoutSubviews];
    
    CGFloat leftPadding = IS_IPHONE ? RPTVCHorizontalOuterPadding : 0;
	CGFloat contentWidth = self.frame.size.width - leftPadding * 2;
    
    CGRect frame = CGRectMake(leftPadding, 0, contentWidth, self.frame.size.height);
    self.postView.frame = frame;
    
    CGFloat sideBorderX = IS_IPHONE ? RPTVCHorizontalOuterPadding - 1 : 0; // Just to the left of the container
    CGFloat sideBorderHeight = self.frame.size.height - RPTVCVerticalOuterPadding; // Just below it
    self.sideBorderView.frame = CGRectMake(sideBorderX, 1, self.frame.size.width - sideBorderX * 2, sideBorderHeight);
}

- (void)configureCell:(ReaderPost *)post withWidth:(CGFloat)width{
	self.post = post;
    [self.postView configurePost:post withWidth:width];
}

@end
