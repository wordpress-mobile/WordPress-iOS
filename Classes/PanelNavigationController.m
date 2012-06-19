//
//  PanelNavigationControllerViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 5/21/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>
#import "PanelNavigationController.h"
#import "PanelNavigationConstants.h"
#import "PanelViewWrapper.h"

#pragma mark -

@interface PanelNavigationController () <UIGestureRecognizerDelegate>
@property (nonatomic, retain) UINavigationController *navigationController;
// FIXME: masterView is a shortcut to masterViewController.view while detailView
// is a container for detailViewController.view, which can be confusing
@property (nonatomic, retain) UIView *detailView;
@property (nonatomic, readonly) UIView *masterView;
@property (nonatomic, readonly) UIView *rootView;
@property (nonatomic, readonly) UIView *topView;
@property (nonatomic, readonly) UIView *lastVisibleView;
@property (nonatomic, retain) NSMutableArray *detailViewControllers;
@property (nonatomic, retain) NSMutableArray *detailViews;
@property (nonatomic, retain) NSMutableArray *detailViewWidths;
@property (nonatomic, retain) UIButton *detailTapper;
@property (nonatomic, retain) UIPanGestureRecognizer *panner;
@property (nonatomic, retain) UITapGestureRecognizer *tapper;
@property (nonatomic, retain) UIImageView *backgroundImageView;

- (void)showSidebar;
- (void)showSidebarAnimated:(BOOL)animated;
- (void)closeSidebar;
- (void)closeSidebarAnimated:(BOOL)animated;
- (void)disableDetailView;
- (void)enableDetailView;
- (void)prepareDetailView:(UIView *)view;
- (void)addShadowTo:(UIView *)view;
- (void)removeShadowFrom:(UIView *)view;
- (void)applyCorners;
- (void)roundViewCorners: (UIView *)view forCorners: (UIRectCorner)rectCorner;
- (void)setScrollsToTop:(BOOL)scrollsToTop forView:(UIView *)view;
- (void)addPanner;
- (void)removePanner;
- (void)addTapper;
- (void)removeTapper;
- (void)setFrameForViewController:(UIViewController *)viewController;
- (void)setViewOffset:(CGFloat)offset forView:(UIView *)view;
- (void)setStackOffset:(CGFloat)offset duration:(CGFloat)duration;
- (CGFloat)nearestValidOffsetWithVelocity:(CGFloat)velocity;
- (CGFloat)maxOffsetSoft;
- (CGFloat)maxOffsetHard;
- (CGFloat)minOffsetSoft;
- (CGFloat)minOffsetHard;
- (NSInteger)indexForView:(UIView *)view;
- (UIView *)viewForIndex:(NSUInteger)index;
- (UIView *)viewBefore:(UIView *)view;
- (UIView *)viewAfter:(UIView *)view;
- (NSArray *)partiallyVisibleViews;
- (BOOL)viewControllerExpectsWidePanel:(UIViewController *)controller;
- (void)relayAppearanceMethod:(void(^)(UIViewController* controller))relay;

- (UIView *)createWrapViewForViewController:(UIViewController *)controller;
- (PanelViewWrapper *)wrapViewForViewController:(UIViewController *)controller;
- (UIView *)viewOrViewWrapper:(UIView *)view;

@end

@interface UIViewController (PanelNavigationController_Internal)
- (void)setPanelNavigationController:(PanelNavigationController *)panelNavigationController;
@end

@interface UIViewController (PanelNavigationController_ViewContainmentEmulation)

- (void)addChildViewController:(UIViewController *)childController;
- (void)removeFromParentViewController;
- (void)willMoveToParentViewController:(UIViewController *)parent;
- (void)didMoveToParentViewController:(UIViewController *)parent;

- (BOOL)vdc_shouldRelay;
- (void)vdc_viewWillAppear:(bool)animated;
- (void)vdc_viewDidAppear:(bool)animated;
- (void)vdc_viewWillDisappear:(bool)animated;
- (void)vdc_viewDidDisappear:(bool)animated;

@end

#pragma mark -

@implementation PanelNavigationController {
    CGFloat _panOrigin;
    CGFloat _stackOffset;
    BOOL _isAppeared;
}
@synthesize detailViewController = _detailViewController;
@synthesize masterViewController = _masterViewController;
@synthesize navigationController = _navigationController;
@synthesize detailView = _detailView;
@synthesize detailViewControllers = _detailViewControllers;
@synthesize detailViews = _detailViews;
@synthesize detailViewWidths = _detailViewWidths;
@synthesize detailTapper = _detailTapper;
@synthesize panner = _panner;
@synthesize tapper = _tapper;
@synthesize backgroundImageView = _backgroundImageView;

- (void)dealloc {
    self.detailViewController.panelNavigationController = nil;
    self.detailViewController = nil;
    self.masterViewController = nil;
    self.navigationController = nil;
    self.detailViewControllers = nil;
    self.detailViews = nil;
    self.detailViewWidths = nil;
    self.detailTapper = nil;
    self.panner = nil;
    self.tapper = nil;

    [super dealloc];
}

- (id)initWithDetailController:(UIViewController *)detailController masterViewController:(UIViewController *)masterController {
    self = [super init];
    if (self) {
        _isAppeared = NO;
        if (IS_IPHONE) {
            _navigationController = [[UINavigationController alloc] initWithRootViewController:detailController];
        } else {
            _detailViewControllers = [[NSMutableArray alloc] init];
            _detailViews = [[NSMutableArray alloc] init];
            _detailViewWidths = [[NSMutableArray alloc] init];
        }
        self.detailViewController = detailController;
        self.masterViewController = masterController;
    }
    return self;
}

- (void)loadView {
    _isAppeared = NO;
    self.view = [[[UIView alloc] init] autorelease];
    self.view.frame = [UIScreen mainScreen].applicationFrame;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.autoresizesSubviews = YES;
    self.view.clipsToBounds = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.detailView = [[[UIView alloc] init] autorelease];
    self.detailView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.detailView.autoresizesSubviews = YES;
    self.detailView.clipsToBounds = YES;
    [self.view addSubview:self.detailView];
    
    if (self.navigationController) {
        [self.navigationController willMoveToParentViewController:self];
        [self addChildViewController:self.navigationController];
        [self.navigationController didMoveToParentViewController:self];
        self.detailViewController.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"list"] style:UIBarButtonItemStyleBordered target:self action:@selector(showSidebar)] autorelease];
    }
    self.detailView.frame = CGRectMake(0, 0, DETAIL_WIDTH, DETAIL_HEIGHT);
    [self.detailViews addObject:self.detailView];
    [self.detailViewWidths addObject:[NSNumber numberWithFloat:DETAIL_WIDTH]];
    _stackOffset = 0;
    if (IS_IPAD) {
        self.backgroundImageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fabric"]] autorelease];
        self.backgroundImageView.frame = CGRectMake(DETAIL_LEDGE_OFFSET, 0, self.view.frame.size.width - DETAIL_LEDGE_OFFSET, DETAIL_HEIGHT);
        self.backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.view insertSubview:self.backgroundImageView belowSubview:self.detailView];
        [self showSidebarAnimated:NO];
    }
}

- (void)viewDidUnload {
    self.detailView = nil;
    self.detailViews = nil;
    self.detailViewWidths = nil;
    self.backgroundImageView = nil;

    if (self.navigationController) {
        [self.navigationController willMoveToParentViewController:nil];
        [self.navigationController removeFromParentViewController];
        [self.navigationController didMoveToParentViewController:nil];
    }
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    UIView *viewToPrepare = nil;
    if (self.navigationController) {
        [self.navigationController.view removeFromSuperview];
        [self.detailView addSubview:self.navigationController.view];
        [self.navigationController viewWillAppear:animated];
        viewToPrepare = self.navigationController.view;
    } else {
        [self.detailViewController.view removeFromSuperview];
        
        UIView *wrappedView = [self createWrapViewForViewController:self.detailViewController];
        [self.detailView addSubview:wrappedView];
        viewToPrepare = wrappedView;

        [self.detailViewController viewWillAppear:animated];
    }
    [self.masterViewController.view removeFromSuperview];
    self.masterView.frame = CGRectMake(0, 0, DETAIL_LEDGE_OFFSET, self.view.frame.size.height);
    self.masterView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:self.masterViewController.view belowSubview:self.detailView];
    // FIXME: keep sliding status
    [self prepareDetailView:viewToPrepare];

    [self addPanner];
    [self addTapper];
    [self relayAppearanceMethod:^(UIViewController *controller) {
        [controller viewWillAppear:animated];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    _isAppeared = YES;
    [self relayAppearanceMethod:^(UIViewController *controller) {
        [controller viewDidAppear:animated];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self removePanner];
    [self removeTapper];
    [self relayAppearanceMethod:^(UIViewController *controller) {
        [controller viewWillDisappear:animated];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    _isAppeared = NO;
    [self relayAppearanceMethod:^(UIViewController *controller) {
        [controller viewDidDisappear:animated];
    }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:interfaceOrientation duration:duration];

    int viewCount = [self.detailViews count];
    for (int i = 0; i < viewCount; i++) {
        UIViewController *vc;
        if (i == 0) {
            vc = self.detailViewController;
        } else {
            vc = [self.detailViewControllers objectAtIndex:i - 1];
        }
        [self setFrameForViewController:vc];
    }
    [self setStackOffset:[self nearestValidOffsetWithVelocity:0] duration:duration];
    [self relayAppearanceMethod:^(UIViewController *controller) {
        [controller willAnimateRotationToInterfaceOrientation:interfaceOrientation duration:duration];
    }];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    [self relayAppearanceMethod:^(UIViewController *controller) {
        [controller willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [self relayAppearanceMethod:^(UIViewController *controller) {
        [controller didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }];
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

    [self.navigationController didReceiveMemoryWarning];
    [self.masterViewController didReceiveMemoryWarning];
    [self.detailViewController didReceiveMemoryWarning];
    [self.detailViewControllers makeObjectsPerformSelector:@selector(didReceiveMemoryWarning)];
    
}

#pragma mark - View Wrapping

- (PanelViewWrapper *)wrapViewForViewController:(UIViewController *)controller {
    UIView *view = controller.view;
    if ([[view superview] isKindOfClass:[PanelViewWrapper class]]) {
        return (PanelViewWrapper *)[view superview];
    }
    return nil;
}

- (UIView *)createWrapViewForViewController:(UIViewController *)controller {
    if (self.navigationController) {
        return controller.view;
    }
    UIView *view = [self wrapViewForViewController:controller];
    if (view == nil) {
        return [[[PanelViewWrapper alloc] initWithViewController:controller] autorelease];
    }
    return view;
}

- (UIView *)viewOrViewWrapper:(UIView *)view {
    if ([[view superview] isKindOfClass:[PanelViewWrapper class]]) {
        return [view superview];
    }
    return view;
}


#pragma mark - Toolbar wrangling.

- (UIToolbar *)toolbarForViewController:(UIViewController *)controller {
    return [[self wrapViewForViewController:controller] toolbar];
}


- (BOOL)isToolbarHiddenForViewController:(UIViewController *)controller {
    return [[self wrapViewForViewController:controller] isToolbarHidden];
}


- (void)setToolbarHidden:(BOOL)hidden forViewController:(UIViewController *)controller {
    [self setToolbarHidden:hidden forViewController:controller animated:YES];
}


- (void)setToolbarHidden:(BOOL)hidden forViewController:(UIViewController *)controller animated:(BOOL)animated {
    [[self wrapViewForViewController:controller] setToolbarHidden:hidden animated:animated];
}


#pragma mark - Property accessors

- (UIView *)masterView {
    return self.masterViewController.view;
}

- (UIView *)rootView {
    return self.rootViewController.view;
}

- (UIView *)topView {
    if ([self.detailViewControllers count] == 0) {
        return self.detailView;
    } else {
        return [self viewOrViewWrapper:self.topViewController.view];
    }
}

- (UIView *)lastVisibleView {
    __block UIView *view = self.detailView;
    [self.detailViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIView *vcView = [(UIViewController *)obj view];
        if (CGRectGetMinX(vcView.frame) < self.rootView.bounds.size.width) {
            view = vcView;
        } else {
            *stop = YES;
        }
    }];

    return [self viewOrViewWrapper:view];
}

- (UIViewController *)topViewController {
    if (self.navigationController) {
        return self.navigationController.topViewController;
    } else {
        if ([self.detailViewControllers count] > 0) {
            return [self.detailViewControllers lastObject];
        } else {
            return self.detailViewController;
        }
    }
}

- (UIViewController *)visibleViewController {
    if (self.modalViewController) {
        return self.modalViewController;
    } else if (self.navigationController) {
        return self.navigationController.visibleViewController;
    } else {
        return self.detailViewController;
    }
}

-  (UIViewController *)rootViewController {
    if (self.navigationController) {
        return self.navigationController;
    } else {
        return self.detailViewController;
    }
}

- (NSArray *)viewControllers {
    if (self.navigationController) {
        return self.navigationController.viewControllers;
    } else {
        NSMutableArray *arr = [[self.detailViewControllers mutableCopy] autorelease];
        [arr insertObject:self.detailViewController atIndex:0];
        return arr;
    }
}

- (void)setDetailViewController:(UIViewController *)detailViewController {
    [self setDetailViewController:detailViewController closingSidebar:YES];
}


- (BOOL)viewControllerExpectsWidePanel:(UIViewController *)controller {
    if ([controller respondsToSelector:@selector(expectsWidePanel)]) {
        return (BOOL)[controller performSelector:@selector(expectsWidePanel)];
    }
    return NO;
}


- (void)setDetailViewController:(UIViewController *)detailViewController closingSidebar:(BOOL)closingSidebar {
    if (_detailViewController == detailViewController) return;

    BOOL oldWasWide = [self viewControllerExpectsWidePanel:_detailViewController];
    
    UIBarButtonItem *sidebarButton = nil;
    
    [self popToRootViewControllerAnimated:NO];

    if (_detailViewController) {
        if (self.navigationController) {
            sidebarButton = [_detailViewController.navigationItem.leftBarButtonItem retain];
        } else {
            if (_isAppeared) {
                [_detailViewController vdc_viewWillDisappear:NO];
            }
            
            UIView *view = [self viewOrViewWrapper:_detailViewController.view];
            [view removeFromSuperview];

            if (_isAppeared) {
                [_detailViewController vdc_viewDidDisappear:NO];
            }
            [_detailViewController willMoveToParentViewController:nil];
            [_detailViewController setPanelNavigationController:nil];
            [_detailViewController removeFromParentViewController];
            [_detailViewController didMoveToParentViewController:nil];

        }
        [_detailViewController release];
    }

    _detailViewController = detailViewController;

    if (_detailViewController) {
        [_detailViewController retain];
        [_detailViewController setPanelNavigationController:self];
        if (self.navigationController) {
            [self.navigationController setViewControllers:[NSArray arrayWithObject:_detailViewController] animated:NO];
            if (sidebarButton == nil) {
                sidebarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"list"] style:UIBarButtonItemStyleBordered target:self action:@selector(showSidebar)];
            }
            _detailViewController.navigationItem.leftBarButtonItem = sidebarButton;
            [sidebarButton release];
        } else {
            [_detailViewController willMoveToParentViewController:self];
            [self addChildViewController:_detailViewController];
            if (_isAppeared) {
                [_detailViewController vdc_viewWillAppear:NO];
            }

            UIView *wrappedView = [self createWrapViewForViewController:_detailViewController];


            BOOL newIsWide = [self viewControllerExpectsWidePanel:_detailViewController];
            
            if (newIsWide != oldWasWide) {
                CGRect frm = self.detailView.frame;
                if (newIsWide) {
                    frm.origin.x = self.view.bounds.size.width - IPAD_WIDE_PANEL_WIDTH;
                    frm.size.width = IPAD_WIDE_PANEL_WIDTH;
                } else {
                    frm.origin.x = SIDEBAR_WIDTH;
                    frm.size.width = DETAIL_WIDTH;
                }
                // the size changed so update the stored width and the width and position of the detailView controller
                [self.detailViewWidths removeObjectAtIndex:0];
                [self.detailViewWidths insertObject:[NSNumber numberWithFloat:frm.size.width] atIndex:0];
                if(self.detailView.frame.origin.x != frm.origin.x) {
                    [UIView animateWithDuration:0.3 animations:^{
                        self.detailView.frame = frm;
                    }];
                    _stackOffset = ABS(SIDEBAR_WIDTH - frm.origin.x);
                } else {
                    self.detailView.frame = frm; // update the width regardless.
                }
            }
            
            [self prepareDetailView:wrappedView];
            [self.detailView addSubview:wrappedView];
            
            if (_isAppeared) {
                [_detailViewController vdc_viewDidAppear:NO];
            }
            [_detailViewController didMoveToParentViewController:self];
        }
    }

    if (IS_IPHONE && closingSidebar) {
        [self closeSidebar];
    }
}

- (void)setMasterViewController:(UIViewController *)masterViewController {
    /*
     When replacing the master view controller:
     
     - Call the right UIViewController containment methods
     - On iPhone: Set/restore scrollsToTop. Only one scroll view can have it enabled if we
     want to be able to scroll by tapping on the status bar
     - On iPad: scroll to top is magically awesome and decides which scroll view to scroll
     depending on where you tap
     - Replace the master view with the new one
     */
    if (_masterViewController == masterViewController) return;

    if (_masterViewController) {
        if (IS_IPHONE) {
            [self setScrollsToTop:YES forView:_masterViewController.view];
        }
        [_masterViewController willMoveToParentViewController:nil];
        [_masterViewController setPanelNavigationController:nil];
        [_masterViewController removeFromParentViewController];
        [_masterViewController didMoveToParentViewController:nil];
        [_masterViewController release];
    }

    _masterViewController = masterViewController;

    if (_masterViewController) {
        [_masterViewController retain];
        [_masterViewController willMoveToParentViewController:self];
        [self addChildViewController:_masterViewController];
        [_masterViewController setPanelNavigationController:self];
        [_masterViewController didMoveToParentViewController:self];
        if (IS_IPHONE) {
            [self setScrollsToTop:NO forView:_masterViewController.view];
        }
    }
}

#pragma mark - Sidebar control

- (void)showSidebar {
    [self showSidebarAnimated:YES];
}

- (void)showSidebarAnimated:(BOOL)animated {
    [UIView animateWithDuration:OPEN_SLIDE_DURATION(animated) delay:0 options:0 | UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self addShadowTo:self.detailView];
        self.masterViewController.view.hidden = NO;
        [self setStackOffset:0 duration:0];
        [self disableDetailView];
    } completion:^(BOOL finished) {
    }];
}

- (void)closeSidebar {
    [self closeSidebarAnimated:YES];
}

- (void)closeSidebarAnimated:(BOOL)animated {
    [UIView animateWithDuration:OPEN_SLIDE_DURATION(animated) delay:0 options:0 | UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self setStackOffset:(DETAIL_LEDGE_OFFSET - DETAIL_OFFSET) duration:0];
    } completion:^(BOOL finished) {
        [self enableDetailView];
    }];
}

- (void)centerTapped {
    [self closeSidebar];
}

- (void)disableDetailView {
    if (IS_IPAD) return;

    // TODO: remove pan recognizer?
    if (!self.detailTapper) {
        self.detailTapper = [UIButton buttonWithType:UIButtonTypeCustom];
        self.detailTapper.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.detailTapper.frame = self.detailView.bounds;
        [self.detailView addSubview:self.detailTapper];
        [self.detailTapper addTarget:self action:@selector(centerTapped) forControlEvents:UIControlEventTouchUpInside];
        self.detailTapper.backgroundColor = [UIColor clearColor];
        UIPanGestureRecognizer *panner = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)] autorelease];
        panner.cancelsTouchesInView = YES;
        panner.delegate = self;
        [self.detailTapper addGestureRecognizer:panner];
    }
    
    self.detailTapper.frame = self.detailView.bounds;

    // Switch scroll to top behavior to master view
    [self setScrollsToTop:NO forView:[self viewOrViewWrapper:self.detailViewController.view]];
    [self setScrollsToTop:YES forView:self.masterView];
}

- (void)enableDetailView {
    if (IS_IPAD) return;

    if (self.detailTapper) {
        [self.detailTapper removeTarget:self action:@selector(centerTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.detailTapper removeFromSuperview];
    }

    self.detailTapper = nil;

    // Restore scroll to top behavior to detail view
    [self setScrollsToTop:NO forView:self.masterView];
    [self setScrollsToTop:YES forView:[self viewOrViewWrapper:self.detailViewController.view]];
}

- (void)prepareDetailView:(UIView *)view {
    CGFloat newPanelWidth = DETAIL_WIDTH;
    
    if (IS_IPAD && [self viewControllerExpectsWidePanel:self.detailViewController]) {
        newPanelWidth = IPAD_WIDE_PANEL_WIDTH;
    }
    
    view.frame = CGRectMake(0, 0, newPanelWidth, DETAIL_HEIGHT);
    [self applyCorners];
}

- (void)addShadowTo:(UIView *)view {
    view.layer.masksToBounds = NO;
    view.layer.shadowRadius = 10.0f;
    view.layer.shadowOpacity = 0.5f;
    view.layer.shadowColor = [[UIColor blackColor] CGColor];
    view.layer.shadowOffset = CGSizeZero;
    view.layer.shadowPath = [[UIBezierPath bezierPathWithRoundedRect:view.bounds cornerRadius:PANEL_CORNER_RADIUS] CGPath];
}

- (void)removeShadowFrom:(UIView *)view {
    view.layer.shadowOpacity = 0.0f;
}

- (void)applyCorners{
    if (IS_IPAD) {
        for (int i=0; i < [self.detailViews count]; i++) {
            UIView *view = [self.detailViews objectAtIndex:i];
            if (i == 0 && [self.detailViews count] == 1) {
                [self roundViewCorners:view forCorners:UIRectCornerAllCorners];
            }
            else if (i ==0) {
                [self roundViewCorners:view forCorners:UIRectCornerTopLeft|UIRectCornerBottomLeft];
            }
            else if (i == [self.detailViews count] - 1) {
                //[self roundViewCorners:view forCorners:UIRectCornerTopRight|UIRectCornerBottomRight];
                [self addShadowTo:view];
            }
            else {
                view.layer.mask = nil;
            }
        }
    }
}

- (void)roundViewCorners: (UIView *)view forCorners:(UIRectCorner)rectCorner {

    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:view.bounds 
                                                   byRoundingCorners: rectCorner
                                                         cornerRadii:CGSizeMake(PANEL_CORNER_RADIUS, PANEL_CORNER_RADIUS)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = view.bounds;
    maskLayer.path = maskPath.CGPath;
    view.layer.mask = maskLayer;
}

- (void)setScrollsToTop:(BOOL)scrollsToTop forView:(UIView *)view {
    if ([view respondsToSelector:@selector(setScrollsToTop:)]) {
        [(UIScrollView *)view setScrollsToTop:scrollsToTop];
    } else {
        // Search for a subview that will respond
        [view.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj respondsToSelector:@selector(setScrollsToTop:)]) {
                [(UIScrollView *)obj setScrollsToTop:scrollsToTop];
                *stop = YES;
            }
        }];
    }
}

#pragma mark - Panning

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.panner) {
    } else if (gestureRecognizer == self.tapper) {
        NSLog(@"should begin gesture: %@", gestureRecognizer);
        CGPoint point = [gestureRecognizer locationInView:self.view];

        __block UIView *touchedView = nil;
        [self.detailViews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIView *view = (UIView *)obj;
            if (CGRectContainsPoint(view.frame, point)) {
                touchedView = view;
                *stop = YES;
            }
        }];
        if (touchedView && [[self partiallyVisibleViews] containsObject:touchedView]) {
            NSLog(@"Touched view: %@", touchedView);
            UIView *nextView = [self viewAfter:touchedView];
            CGFloat offset;
            if (CGRectGetMaxX(touchedView.frame) > CGRectGetMaxX(self.view.bounds)) {
                // Partly off-screen, move left
                offset = CGRectGetMaxX(touchedView.frame) - CGRectGetMaxX(self.view.bounds);
            } else if (nextView && CGRectGetMinX(nextView.frame) < CGRectGetMaxX(touchedView.frame)) {
                // Covered by another view, move right
                offset = CGRectGetMinX(nextView.frame) - CGRectGetMaxX(touchedView.frame);
            }
            [self setStackOffset:_stackOffset + offset duration:DURATION_FAST];
            return YES;
        } else {
            return NO;
        }
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer == self.panner) {
//        if (_stackOffset > 0) {
//            CGFloat detail_ledge_offset = DETAIL_LEDGE_OFFSET;
//            CGFloat detail_offset = DETAIL_OFFSET;
//            NSLog(@"ledge: %.1f  offset: %.1f  stackoffset: %.1f", detail_ledge_offset, detail_offset, _stackOffset);
//            _panOrigin = detail_ledge_offset + detail_offset + _stackOffset;
//            _panOrigin =  _stackOffset*3;
//        } else {
            _panOrigin = _stackOffset;
//        }

        NSLog(@"panOrigin: %.0f", _panOrigin);
    }
    return YES;
}

- (void)panned:(UIPanGestureRecognizer *)sender {
    /*
     _stackOffset is how many pixels the views are dragged to the left from the initial (sidebar open) position
     
     Limits:
     * Min: 0 [soft], - ( width - DETAIL_LEDGE_OFFSET) [hard]
     * Max (1 panel): 0 [soft], (sidebar width - ledge) [hard]
     * Max (2+ panels: (v[n]-v[n-1]) + v[n-2] + ... + v[0]) [soft],
                       sum(v[0..n-1]) [hard]
     Note that v[0] is only used if n > 2.
     
     When a soft limit is reached, we add elasticity
     Views can't move over hard limits
     
     TODO: store lastFullyVisible for rotation
     */
    CGPoint p = [sender translationInView:self.rootViewController.view];
    CGFloat offset = _panOrigin - p.x;
    NSLog(@"offset: %.1f", offset);
    
    /*
     Step 1: setup boundaries
     */
    CGFloat minSoft = [self minOffsetSoft];
    CGFloat minHard = [self minOffsetHard];
    CGFloat maxSoft = [self maxOffsetSoft];
    CGFloat maxHard = [self maxOffsetHard];
    NSLog(@"min [%.1f,%.1f] max[%.1f,%.1f]", minSoft, minHard, maxSoft, maxHard);
    NSLog(@"before adjusting: %.1f", offset);
    CGFloat limitOffset = MAX(minSoft, MIN(maxSoft, offset));
    CGFloat diff = ABS(ABS(offset) - ABS(limitOffset));
    // if we're outside the allowed bounds
    if (diff > 0) {
        // Reduce the dragged distance
        diff = diff / logf(diff + 1) * 2;
        offset = limitOffset + (offset < limitOffset ? -diff : diff);
    }
    NSLog(@"after soft adjusting: %.1f", offset);
    offset = MAX(minHard, MIN(maxHard, offset));
    NSLog(@"after hard adjusting: %.1f", offset);
    
    /*
     Step 2: calculate each view position
     */
    [self setStackOffset:offset duration:0];

    /*
     Step 3: when released, calculate final positions
     */
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGFloat velocity = [sender velocityInView:self.view].x;
        if (IS_IPAD) {
            CGFloat nearestOffset = [self nearestValidOffsetWithVelocity:-velocity];
            [self setStackOffset:nearestOffset duration:DURATION_FAST];
        } else {
            // TODO: multiple panel panning
            if (ABS(velocity) < 100) {
                if (offset < DETAIL_LEDGE_OFFSET / 3) {
                    [self showSidebar];
                } else {
                    [self closeSidebar];
                }
            } else if (velocity > 0) {
                // Going right
                [self showSidebar];
            } else {
                [self closeSidebar];
            }
        }
    }
}

- (void)addPanner {
    [self removePanner];
    
    UIPanGestureRecognizer *panner = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)] autorelease];
    panner.cancelsTouchesInView = YES;
    panner.delegate = self;
    self.panner = panner;
    if (self.navigationController) {
        [self.navigationController.navigationBar addGestureRecognizer:panner];
    } else {
        [self.view addGestureRecognizer:panner];
    }
}

- (void)removePanner {
    if (self.panner) {
        [self.panner.view removeGestureRecognizer:self.panner];
    }
    self.panner = nil;
}

- (void)addTapper {
    [self removeTapper];

    if (IS_IPAD) {
        UITapGestureRecognizer *tapper = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)] autorelease];
        tapper.cancelsTouchesInView = YES;
        tapper.delegate = self;
        self.tapper = tapper;
        [self.view addGestureRecognizer:tapper];
    }
}

- (void)removeTapper {
    if (self.tapper) {
        [self.tapper.view removeGestureRecognizer:self.tapper];
    }
    self.tapper = nil;
}

- (void)tapped:(UITapGestureRecognizer *)sender {
    // Shouldn't really get here since we deny the touch in the delegate
}

- (void)setFrameForViewController:(UIViewController *)viewController {
    CGFloat newPanelWidth = DETAIL_WIDTH;
    CGRect frame;
    
    if (IS_IPAD && [self viewControllerExpectsWidePanel:viewController]) {
        newPanelWidth = IPAD_WIDE_PANEL_WIDTH;
    }
    
    UIView *view = nil;
    if (self.navigationController) {
        frame = viewController.view.frame;
        frame.size.width = newPanelWidth;
        view = viewController.view;
    } else {
        view = [self viewOrViewWrapper:viewController.view];
        frame = view.frame;
        frame.size.width = newPanelWidth;
    }
    view.frame = frame;
    [self prepareDetailView:view]; // Call this again to fix the masking bounds set for rounded corners.
    NSLog(@"Frame Set For View Controller : %.1f %.1f %.1f %.1f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
}

- (void)setViewOffset:(CGFloat)offset forView:(UIView *)view {
    view = [self viewOrViewWrapper:view];
    
    CGRect frame = view.frame;
    frame.origin.x = MAX(0, MIN(offset, self.view.bounds.size.width));
    view.frame = frame;
}

- (void)setStackOffset:(CGFloat)offset duration:(CGFloat)duration {
    CGFloat remainingOffset = offset;
    
    BOOL expectsWidePanels = [self viewControllerExpectsWidePanel:self.detailViewController];
    CGFloat detailLedgeOffset = DETAIL_LEDGE_OFFSET;
    if (expectsWidePanels){
        detailLedgeOffset = 44.0f;
    }
    
    CGFloat usedOffset = MIN(DETAIL_LEDGE_OFFSET - DETAIL_OFFSET, remainingOffset);
    CGFloat viewX = DETAIL_LEDGE_OFFSET - usedOffset;
    if (duration > 0) {
        [UIView beginAnimations:@"stackOffset" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:duration];
    }
    [self setViewOffset:viewX forView:self.detailView];
    remainingOffset -= usedOffset;

    NSInteger viewCount = [self.detailViews count];
    for (NSInteger i = 1; i < viewCount; i++) {        
        UIView *view = [self.detailViews objectAtIndex:i];
        UIView *previousView = [self.detailViews objectAtIndex:(i - 1)];
        usedOffset = MIN(previousView.frame.size.width, remainingOffset);
        viewX += previousView.frame.size.width;
        viewX -= usedOffset;
        
        // ZOMG this is horrible, but without it the secondary detail does not position correctly.
        if (offset >= 956.0f && i == viewCount -1 && expectsWidePanels && UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
            viewX += 44.0f;
        }
        
        [self setViewOffset:viewX forView:view];
        remainingOffset -= usedOffset;
    }
    [UIView commitAnimations];
    _stackOffset = offset - remainingOffset;

    NSLog(@"partially visible: %@", [self partiallyVisibleViews]);
}

- (CGFloat)nearestValidOffsetWithVelocity:(CGFloat)velocity {
    NSLog(@"nearest with velocity: %.2f", velocity);
    CGFloat offset = 0;

    // If we're working with wide panels we need to adjust the offset for the wide panel
    // This makes sure the lefthand side of the panel is correctly positioned over the sidebar.
    if ([self viewControllerExpectsWidePanel:_detailViewController]) {
        if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
            offset = DETAIL_LEDGE_OFFSET - (self.view.bounds.size.width - IPAD_WIDE_PANEL_WIDTH);
        }
    }
    
    CGFloat remainingVelocity = velocity;
    CGFloat velocityFactor = 10;
    CGFloat diff = ABS(_stackOffset + remainingVelocity / velocityFactor - offset);
    CGFloat previousOffset = offset;
    CGFloat previousDiff = diff;
    
    // View 0
    offset += DETAIL_LEDGE_OFFSET - DETAIL_OFFSET;
    diff = ABS(_stackOffset + remainingVelocity / velocityFactor - offset);
    remainingVelocity -= remainingVelocity / velocityFactor;
    if (diff > previousDiff) {
        return previousOffset;
    } else {
        previousOffset = offset;
        previousDiff = diff;
    }

    NSUInteger viewCount = [self.detailViews count];
    for (int i = 0; i < viewCount - 2; i++) {
        UIView *view = [self.detailViews objectAtIndex:i];
        offset += view.frame.size.width;
        diff = ABS(_stackOffset + remainingVelocity / velocityFactor - offset);
        remainingVelocity -= remainingVelocity / velocityFactor;
        if (diff > previousDiff) {
            return previousOffset;
        } else {
            previousOffset = offset;
            previousDiff = diff;
        }
    }
    
    offset += DETAIL_LEDGE;
    offset += [[self.detailViewWidths objectAtIndex:(viewCount - 1)] floatValue];
    offset += [[self.detailViewWidths objectAtIndex:(viewCount - 2)] floatValue];
    offset -= self.view.bounds.size.width;
    diff = ABS(_stackOffset + remainingVelocity / velocityFactor - offset);
    remainingVelocity -= remainingVelocity / velocityFactor;
    if (diff > previousDiff) {
        return previousOffset;
    } else {
        previousOffset = offset;
        previousDiff = diff;
    }

    return previousOffset;
}

- (CGFloat)maxOffsetSoft {
    CGFloat maxSoft;
    NSUInteger viewCount = [self.detailViewWidths count];
    if (IS_IPHONE) {
        maxSoft = DETAIL_LEDGE_OFFSET;
    } else if (viewCount <= 1) {
        maxSoft = DETAIL_LEDGE_OFFSET - DETAIL_OFFSET;
    } else {
        maxSoft = DETAIL_LEDGE_OFFSET - DETAIL_OFFSET;
        maxSoft+= DETAIL_LEDGE;
        maxSoft+= [[self.detailViewWidths objectAtIndex:(viewCount - 1)] floatValue];
        maxSoft+= [[self.detailViewWidths objectAtIndex:(viewCount - 2)] floatValue];
        maxSoft-= self.view.bounds.size.width;
        for (int i = viewCount - 3; i >= 0; i--) {
            maxSoft += [[self.detailViewWidths objectAtIndex:i] floatValue];
        }
    }
    return maxSoft;
}

- (CGFloat)maxOffsetHard {
    CGFloat maxHard;
    NSUInteger viewCount = [self.detailViewWidths count];
    if (IS_IPHONE) {
        maxHard = DETAIL_LEDGE_OFFSET;
    } else if (viewCount <= 1) {
        maxHard = DETAIL_LEDGE_OFFSET;
    } else {
        maxHard = DETAIL_LEDGE_OFFSET - DETAIL_OFFSET;
        for (int i = 0; i < viewCount; i++) {
            maxHard += [[self.detailViewWidths objectAtIndex:i] floatValue];
        }
    }
    return maxHard;
}

- (CGFloat)minOffsetSoft {
    return 0.0f;
}

- (CGFloat)minOffsetHard {
    return DETAIL_LEDGE_OFFSET - self.view.bounds.size.width;
}

- (NSInteger)indexForView:(UIView *)view {
    if (view == self.detailView) {
        return 0;
    }
    __block NSInteger index = -1;
    [self.detailViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (view == [obj view]) {
            index = idx + 1;
            *stop = YES;
        }
    }];
    return index;
}

- (UIView *)viewForIndex:(NSUInteger)index {
    if (index == 0) {
        return self.detailView;
    } else {
        if (index > [self.detailViewControllers count]) {
            return nil;
        }
        return [self viewOrViewWrapper:[[self.detailViewControllers objectAtIndex:(index - 1)] view]];
    }
}

- (UIView *)viewBefore:(UIView *)view {
    if (view == self.detailView) {
        return nil;
    }

    NSInteger index = [self indexForView:view];
    return [self viewForIndex:index - 1];
}

- (UIView *)viewAfter:(UIView *)view {
    return [self viewForIndex:[self indexForView:view] + 1];
}

- (NSArray *)partiallyVisibleViews {
    NSMutableArray *views = [NSMutableArray arrayWithCapacity:[self.detailViews count]];
    [self.detailViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIView *view = (UIView *)obj;
        if (CGRectContainsRect(self.view.bounds, view.frame)) {
            // Fully inside, check for overlapping views
            if (idx + 1 < [self.detailViews count]) {
                UIView *nextView = [self.detailViews objectAtIndex:idx+1];
                if (nextView && CGRectIntersectsRect(view.frame, nextView.frame) && nextView.frame.origin.x > view.frame.origin.x) {
                    [views addObject:view];
                }
            }
        } else if (CGRectIntersectsRect(self.view.bounds, view.frame)) {
            // Intersects, so partly visible
            [views addObject:view];
        }
    }];
    return [NSArray arrayWithArray:views];
}

- (void)relayAppearanceMethod:(void(^)(UIViewController* controller))relay {
    bool shouldRelay = ![self respondsToSelector:@selector(automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers)] || ![self performSelector:@selector(automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers)];

    // don't relay if the controller supports automatic relaying
    if (!shouldRelay)
        return;

    relay(self.masterViewController);
    if (self.navigationController) {
        relay(self.navigationController);
    } else {
        relay(self.detailViewController);
        for (UIViewController *controller in self.detailViewControllers) {
            relay(controller);
        }
    }
}


#pragma mark - Navigation methods

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    WPFLogMethod();
    if (self.navigationController) {
        [viewController setPanelNavigationController:self];
        [self.navigationController pushViewController:viewController animated:animated];
    } else {
        UIView *topView;
        if ([self.detailViewControllers count] == 0) {
            [self closeSidebar];
            topView = self.detailView;
        } else {
            topView = [self viewOrViewWrapper:self.topViewController.view];
        }
        CGRect topViewFrame = topView.frame;
        CGFloat newPanelWidth = DETAIL_WIDTH;
        
        if ([self viewControllerExpectsWidePanel:viewController]) {
            newPanelWidth = IPAD_WIDE_PANEL_WIDTH;
        }
        
        if (CGRectGetMaxX(topViewFrame) + newPanelWidth > self.view.bounds.size.width) {
            // Move previous controller to the left
            topViewFrame.origin.x = MAX(DETAIL_OFFSET, self.view.bounds.size.width - newPanelWidth - topViewFrame.size.width);
            viewController.view.frame = CGRectMake(self.view.bounds.size.width - newPanelWidth, 0.0f, newPanelWidth, DETAIL_HEIGHT);
        } else {
            viewController.view.frame = CGRectMake(CGRectGetMaxX(topViewFrame), 0.0f, newPanelWidth, DETAIL_HEIGHT);
        }
        [viewController willMoveToParentViewController:self];
        if (_isAppeared) {
            [viewController vdc_viewWillAppear:animated];
        }
        [self addChildViewController:viewController];

        UIView *wrappedView = [self createWrapViewForViewController:viewController];
        [self.view addSubview:wrappedView];

        [self.detailViews addObject:wrappedView];
        [self.detailViewWidths addObject:[NSNumber numberWithFloat:newPanelWidth]];
        
        if (_isAppeared) {
            [viewController vdc_viewDidDisappear:animated];
        }

        [self applyCorners];
        
        [UIView animateWithDuration:CLOSE_SLIDE_DURATION(animated) animations:^{
            topView.frame = topViewFrame;
        }];
        [viewController setPanelNavigationController:self];
        [viewController didMoveToParentViewController:self];
        [self.detailViewControllers addObject:viewController];
        [self setStackOffset:[self maxOffsetSoft] duration:0];
    }
}

- (void)pushViewController:(UIViewController *)viewController fromViewController:(UIViewController *)fromViewController animated:(BOOL)animated {
    WPFLogMethod();
    [self popToViewController:fromViewController animated:NO];
    [self pushViewController:viewController animated:YES];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    UIViewController *viewController = nil;
    WPFLogMethod();
    if (self.navigationController) {
        return [self.navigationController popViewControllerAnimated:animated];
    } else {
        if (self.topViewController != self.detailViewController) {
            viewController = self.topViewController;
            [viewController willMoveToParentViewController:nil];
            [viewController vdc_viewWillDisappear:animated];
            [viewController removeFromParentViewController];
            
            UIView *view = [self viewOrViewWrapper:viewController.view];
            [view removeFromSuperview];
//            [viewController.view removeFromSuperview];
            [viewController vdc_viewDidDisappear:animated];
            [viewController didMoveToParentViewController:nil];
            
            // cleanup wrapper and toolbar.
//            [self removeWrapperForView:viewController.view];
            
            [self.detailViewControllers removeLastObject];
            [self.detailViews removeLastObject];
            [self.detailViewWidths removeLastObject];
            
            if ([self.detailViewControllers count] == 0) {
                [self showSidebar];
            }
        }
    }
    return viewController;
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    WPFLogMethod();
    if (self.navigationController) {
        return [self.navigationController popToViewController:viewController animated:animated];
    } else {
        NSMutableArray *poppedControllers = [NSMutableArray array];
        __block BOOL found = NO;        
        [self.detailViewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (obj == viewController) {
                *stop = YES;
                found = YES;
            } else {
                [poppedControllers addObject:obj];
                [self popViewControllerAnimated:animated];
            }
        }];
        if (!found && viewController != self.detailViewController) {
            [poppedControllers addObject:self.detailViewController];
            [self setDetailViewController:viewController];
        }
        return [NSArray arrayWithArray:poppedControllers];
    }
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated {
    WPFLogMethod();
    NSMutableArray *viewControllers = [NSMutableArray array];
    if (self.navigationController) {
        return [self.navigationController popToRootViewControllerAnimated:animated];
    } else {
        NSInteger count = [self.detailViewControllers count];
        for (int i = 0; i < count; i++) {
            [viewControllers addObject:[self popViewControllerAnimated:animated]];
        }
        _stackOffset = 0;
    }
    return [NSArray arrayWithArray:viewControllers];
}


@end

@implementation UIViewController (PanelNavigationController)

@dynamic panelNavigationController;

static const char *panelNavigationControllerKey = "PanelNavigationController";

- (PanelNavigationController *)panelNavigationController {
    return objc_getAssociatedObject(self, panelNavigationControllerKey);
}

- (void)setPanelNavigationController:(PanelNavigationController *)panelNavigationController {
    objc_setAssociatedObject(self, panelNavigationControllerKey, panelNavigationController, OBJC_ASSOCIATION_ASSIGN);
}

@end

@implementation UIViewController (PanelNavigationControllerPanel)

#define OBJC_ADD_METHOD_IF_MISSING(selector,fakeSelector,args)     if (!class_getInstanceMethod(self, selector)) { \
    class_addMethod([UIViewController class], selector, method_getImplementation(class_getInstanceMethod(self, fakeSelector)), args); }


+ (void)load {
    [super load];
    OBJC_ADD_METHOD_IF_MISSING(@selector(addChildViewController:), @selector(fake_addChildViewController:), "v@:@");
    OBJC_ADD_METHOD_IF_MISSING(@selector(removeFromParentViewController), @selector(fake_removeFromParentViewController), "v@:");
    OBJC_ADD_METHOD_IF_MISSING(@selector(willMoveToParentViewController:), @selector(fake_willMoveToParentViewController:), "v@:@");
    OBJC_ADD_METHOD_IF_MISSING(@selector(didMoveToParentViewController:), @selector(fake_didMoveToParentViewController:), "v@:@");
}

- (void)fake_addChildViewController:(UIViewController *)childController {
}

- (void)fake_removeFromParentViewController {
}

- (void)fake_willMoveToParentViewController:(UIViewController *)parent {
}

- (void)fake_didMoveToParentViewController:(UIViewController *)parent {
}

@end

@implementation UIViewController (PanelNavigationController_ViewContainmentEmulation_Fakes)

- (BOOL)vdc_shouldRelay {
    if (self.panelNavigationController)
        return [self.panelNavigationController vdc_shouldRelay];

    return ![self respondsToSelector:@selector(automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers)] || ![self performSelector:@selector(automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers)];
}

- (void)vdc_viewWillAppear:(bool)animated {
    if (![self vdc_shouldRelay])
        return;

    [self viewWillAppear:animated];
}

- (void)vdc_viewDidAppear:(bool)animated{
    if (![self vdc_shouldRelay])
        return;

    [self viewDidAppear:animated];
}

- (void)vdc_viewWillDisappear:(bool)animated{
    if (![self vdc_shouldRelay])
        return;

    [self viewWillDisappear:animated];
}

- (void)vdc_viewDidDisappear:(bool)animated{
    if (![self vdc_shouldRelay])
        return;

    [self viewDidDisappear:animated];
}

@end