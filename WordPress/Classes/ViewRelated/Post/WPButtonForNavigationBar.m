#import "WPButtonForNavigationBar.h"

static CGFloat kDefaultAnimationDuration = 0.3;
static CGFloat kHighlightedAlpha = 0.2f;
static CGFloat kNormalAlpha = 1.0f;

@implementation WPButtonForNavigationBar

#pragma mark - UIView

- (instancetype)init
{
	self = [super init];
	
	if (self) {
		[self setupAnimations];
	}
	
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	
	if (self) {
		[self setupAnimations];
	}
	
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self) {
		[self setupAnimations];
	}
	
	return self;
}

- (UIEdgeInsets)alignmentRectInsets
{
	// IMPORTANT: Keep an eye on this on different iOS versions.  This spacing is for iOS 7 and 8.
	static const CGFloat kDefaultSpacing = 9.0f;
	
	UIEdgeInsets insets = UIEdgeInsetsZero;
	
	if (self.removeDefaultLeftSpacing) {
		insets = UIEdgeInsetsMake(0, kDefaultSpacing - self.leftSpacing, 0, 0);
	}
	
	if (self.removeDefaultRightSpacing) {
		insets = UIEdgeInsetsMake(0, 0, 0, kDefaultSpacing - self.rightSpacing);
	}
	
	return insets;
}

#pragma mark - Animations

- (void)setupAnimations
{
	self.adjustsImageWhenHighlighted = NO;
	
	[self addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
	[self addTarget:self action:@selector(touchDragInside:) forControlEvents:UIControlEventTouchDragInside];
	[self addTarget:self action:@selector(touchDragOutside:) forControlEvents:UIControlEventTouchDragOutside];
}

- (void)touchDown:(id)sender
{
	[self setAlpha:kHighlightedAlpha];
}

- (void)touchDragInside:(id)sender
{
	[UIView animateWithDuration:kDefaultAnimationDuration
					 animations:^void()
	{
		[self setAlpha:kHighlightedAlpha];
	}];
}

- (void)touchDragOutside:(id)sender
{
	[UIView animateWithDuration:kDefaultAnimationDuration
					 animations:^void()
	{
		[self setAlpha:kNormalAlpha];
	}];
}

@end