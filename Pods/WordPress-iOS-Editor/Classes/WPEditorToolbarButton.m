#import "WPEditorToolbarButton.h"

@interface WPEditorToolbarButton ()
@property (nonatomic, weak, readonly) id target;
@property (nonatomic, assign, readonly) SEL selector;
@property (nonatomic, weak, readwrite) UIView* bottomLineView;
@end

static const CGFloat kAnimationDurationFast = 0.1;
static CGFloat kAnimationDurationNormal = 0.3;
static CGFloat kHighlightedAlpha = 0.2f;
static CGFloat kNormalAlpha = 1.0f;

static const int kBottomLineHMargin = 4;
static const int kBottomLineHeight = 2;


@implementation WPEditorToolbarButton

#pragma mark - Init & dealloc

- (void)dealloc
{
	[self removeTarget:self
				action:@selector(touchUpInside:)
	  forControlEvents:UIControlEventTouchUpInside];
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self) {
		[self setupAnimations];
		
		[self addTarget:self
				 action:@selector(touchUpInside:)
	   forControlEvents:UIControlEventTouchUpInside];
	}
	
	return self;
}

#pragma mark - Memory warnings support

- (void)didReceiveMemoryWarning
{
	if (!self.selected) {
		[self destroyBottomLineView];
	}
}

#pragma mark - Animations

- (void)setupAnimations
{
	self.adjustsImageWhenHighlighted = NO;
	
	[self addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
	[self addTarget:self action:@selector(touchDragInside:) forControlEvents:UIControlEventTouchDragInside];
	[self addTarget:self action:@selector(touchDragOutside:) forControlEvents:UIControlEventTouchDragOutside];
}

#pragma mark - Touch handling

- (void)touchDown:(id)sender
{
	[self setAlpha:kHighlightedAlpha];
}

- (void)touchDragInside:(id)sender
{
	[UIView animateWithDuration:kAnimationDurationNormal
					 animations:
     ^{
         [self setAlpha:kHighlightedAlpha];
     }];
}

- (void)touchDragOutside:(id)sender
{
	[UIView animateWithDuration:kAnimationDurationNormal
					 animations:
     ^{
		 [self setAlpha:kNormalAlpha];
	 }];
}

- (void)touchUpInside:(id)sender
{
	[self setAlpha:kNormalAlpha];
	self.selected = !self.selected;
}

#pragma mark - Bottom line

- (void)createBottomLineView
{
	NSAssert(!_bottomLineView, @"The bottom line view should not exist here");
	
	CGRect bottomLineFrame = self.frame;
	bottomLineFrame.origin.x = kBottomLineHMargin;
	bottomLineFrame.origin.y = bottomLineFrame.size.height;
	bottomLineFrame.size.width = bottomLineFrame.size.width - kBottomLineHMargin * 2;
	bottomLineFrame.size.height = kBottomLineHeight;
	
	UIView* bottomLineView = [[UIView alloc] initWithFrame:bottomLineFrame];
	bottomLineView.backgroundColor = self.tintColor;
	bottomLineView.userInteractionEnabled = NO;
	
	[self addSubview:bottomLineView];
	self.bottomLineView = bottomLineView;
}

- (void)destroyBottomLineView
{
	NSAssert(_bottomLineView, @"The bottom line view should exist here");
	
	[self.bottomLineView removeFromSuperview];
	self.bottomLineView = nil;
}

- (void)slideInBottomLineView
{
	if (!_bottomLineView) {
		[self createBottomLineView];
	}
	
	CGRect newFrame = self.bottomLineView.frame;
	newFrame.origin.y -= kBottomLineHeight;
	
	[UIView animateWithDuration:kAnimationDurationFast animations:^{
		self.bottomLineView.frame = newFrame;
	}];
}

- (void)slideOutBottomLineView
{
	if (self.bottomLineView) {
		CGRect newFrame = self.bottomLineView.frame;
		newFrame.origin.y = self.frame.size.height;
		
		[UIView animateWithDuration:kAnimationDurationFast animations:^{
			self.bottomLineView.frame = newFrame;
		}];
	}
}

#pragma mark - UIControl

- (void)setHighlighted:(BOOL)highlighted
{
	[super setHighlighted:highlighted];
	
	if (highlighted) {
		self.titleLabel.alpha = 0.5f;
		self.imageView.alpha = 0.5f;
		self.bottomLineView.alpha = 0.5f;
	} else {
		self.titleLabel.alpha = 1.0f;
		self.imageView.alpha = 1.0f;
		self.bottomLineView.alpha = 1.0f;
	}
}

- (void)setSelected:(BOOL)selected
{
	BOOL hasChangedSelectedStatus = (selected != self.selected);
	
	[super setSelected:selected];
	
	if (hasChangedSelectedStatus) {
		dispatch_time_t dispatchDelay = dispatch_time(DISPATCH_TIME_NOW,
													  (int64_t)(0.2 * NSEC_PER_SEC));
		
		dispatch_after(dispatchDelay, dispatch_get_main_queue(), ^{
			if (selected) {
				self.tintColor = self.selectedTintColor;
				[self slideInBottomLineView];
			} else {
				self.tintColor = self.normalTintColor;
				[self slideOutBottomLineView];
			}
		});
	}
}

#pragma mark - Tint color

- (void)setNormalTintColor:(UIColor *)normalTintColor
{
	if (_normalTintColor != normalTintColor) {
		_normalTintColor = normalTintColor;
		
		[self setTitleColor:normalTintColor forState:UIControlStateNormal];
		
		if (!self.selected) {
			self.tintColor = normalTintColor;
		}
	}
}

- (void)setSelectedTintColor:(UIColor *)selectedTintColor
{
	if (_selectedTintColor != selectedTintColor) {
		_selectedTintColor = selectedTintColor;
		
		[self setTitleColor:selectedTintColor forState:UIControlStateSelected];
		
		if (self.selected) {
			self.tintColor = selectedTintColor;
		}
	}
}

@end
