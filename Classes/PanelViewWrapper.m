//
//  PanelViewWrapper.m
//  WordPress
//
//  Created by Eric Johnson on 6/12/12.
//

#import "PanelViewWrapper.h"
#import "NSObject+BlockObservation.h"
#import "UIToolbar+Styled.h"

@interface PanelViewWrapper()

// Assign vs retain cos releasing later gets tricky.
@property (nonatomic, assign) UIViewController *viewController;
@property (nonatomic, assign) UIView *wrappedView;
@property (nonatomic, retain) AMBlockToken *observerToken;

- (void)setup;

@end


@implementation PanelViewWrapper

@synthesize toolbar = _toolbar;
@synthesize viewController = _viewController;
@synthesize wrappedView = _wrappedView;
@synthesize observerToken = _observerToken;
@synthesize overlay = _overlay;

- (void)dealloc {
    self.toolbar = nil;
    self.overlay = nil;
    [super dealloc];
}


- (id)initWithViewController:(UIViewController *)controller {
    CGRect frame = controller.view.frame;
    self = [self initWithFrame:frame];
    if (self) {
        [self wrapViewFromController:controller];
    }
    return self;
}


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}


- (void)setup {
    self.backgroundColor = [UIColor clearColor];
    self.autoresizesSubviews = YES;
    self.clipsToBounds = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    CGFloat toolbarHeight = 44.0f;
    CGRect frame = CGRectMake(0.0f, self.frame.size.height, self.frame.size.width, toolbarHeight);
    self.toolbar = [[[UIToolbar alloc] initWithFrame:frame] autorelease];
    self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.toolbar.hidden = YES;

    [self addSubview:self.toolbar];
}


- (void)wrapViewFromController:(UIViewController *)controller {
    [self.viewController removeObserverWithBlockToken:self.observerToken];
    self.viewController = controller;
    self.observerToken = [self.viewController addObserverForKeyPath:@"toolbarItems" task:^(id obj, NSDictionary *change) {
        [self setToolbarItems:self.viewController.toolbarItems];
    }];
    
    // Adopt the view's frame and autoresizing mask. 
    UIView *view = controller.view;
    CGRect frame = view.frame;
    self.frame = frame;
    self.autoresizingMask = view.autoresizingMask;
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // Keep the size but reset the view's origin to 0,0.
    frame.origin.x = 0.0f;
    frame.origin.y = 0.0f;
    view.frame = frame;
    
    // Now the view is wrapped.
    [self insertSubview:view belowSubview:self.toolbar];
    
    // Use the toolbarItems from the controller.
    [self setToolbarItems:controller.toolbarItems];
    
    //add the overlay for fading when partialy hidden
    _overlay = [[UIView alloc] initWithFrame:self.bounds];
    _overlay.backgroundColor = [UIColor blackColor];
    _overlay.alpha = 0.0f;
    _overlay.userInteractionEnabled = NO;
    _overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_overlay];
}


- (NSArray *)toolbarItems {
    return [self.toolbar items];
}


- (void)setToolbarItems:(NSArray *)items {
    [self setToolbarItems:items animated:YES];
}


- (void)setToolbarItems:(NSArray *)items animated:(BOOL)animated {
    [self.toolbar setItems:items animated:animated];
}


- (BOOL)isToolbarHidden {
    return self.toolbar.hidden;
}


- (void)setToolbarHidden:(BOOL)hidden {
    [self setToolbarHidden:hidden animated:YES];
}


- (void)setToolbarHidden:(BOOL)hidden animated:(BOOL)animated {
    if (hidden == self.toolbar.hidden) {
        return;
    }
    
    CGRect viewFrame = self.wrappedView.frame;
    CGRect toolbarFrame = self.toolbar.frame;
    CGFloat height = toolbarFrame.size.height;
    if (hidden) {
        // hiding
        viewFrame.size.height = self.frame.size.height;
        toolbarFrame.origin.y = (self.frame.size.height + height);
    } else {
        // showing
        toolbarFrame.origin.y = (self.frame.size.height - height);
        viewFrame.size.height = toolbarFrame.origin.y;
    }
    
    if (!animated) {
        self.toolbar.hidden = hidden;
        self.toolbar.frame = toolbarFrame;
        self.wrappedView.frame = viewFrame;
    } else {
        if (!hidden) {
            // show before we run the animation so we can see it appear.
            self.toolbar.hidden = NO;
        }
        [UIView animateWithDuration:0.3 animations:^{
            self.toolbar.frame = toolbarFrame;
            self.wrappedView.frame = viewFrame;
        } completion:^(BOOL finished) {
            if (hidden) {
                self.toolbar.hidden = YES;
            }
        }];
    }
}

@end
