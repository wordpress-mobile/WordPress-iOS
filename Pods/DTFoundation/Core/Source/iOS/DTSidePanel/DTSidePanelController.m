//
//  DTSidePanelController.m
//  DTSidePanelController
//
//  Created by Oliver Drobnik on 15.05.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "DTSidePanelController.h"
#import "UIView+DTFoundation.h"
#import "UIViewController+DTSidePanelController.h"
#import "DTLog.h"
#import "DTSidePanelPanGestureRecognizer.h"

@interface UIViewController () // private setter
- (void)setSidePanelController:(DTSidePanelController *)sidePanelController;
@end


@interface DTSidePanelController () <UIGestureRecognizerDelegate>
@end

@implementation DTSidePanelController 
{
	UIView *_centerBaseView;
	UIView *_leftBaseView;
	UIView *_rightBaseView;
	
	CGFloat _leftPanelWidth;
	CGFloat _rightPanelWidth;
	
	CGFloat _minimumVisibleCenterWidth;
	CGPoint _lastTranslation;
	
	CGFloat _animationVelocityMaximum;

	DTSidePanelControllerPanel _panelToPresentAfterLayout;  // the panel presentation to restore after subview layouting
	BOOL _panelIsMoving;  // if the panel is being dragged or being animated
	
	CGPoint _minPanRange;
	CGPoint _maxPanRange;
	
	UITapGestureRecognizer *_tapToCloseGesture;
	DTSidePanelPanGestureRecognizer *_centerPanelPanGesture;
	
	UIViewController *_presentedPanelViewController;
	
	DT_WEAK_VARIABLE id <DTSidePanelControllerDelegate> _sidePanelDelegate;
}

- (void)dealloc
{
	_centerPanelController.sidePanelController = nil;
	_centerPanelController.sidePanelController = nil;
	_centerPanelController.sidePanelController = nil;
	
	_sidePanelDelegate = nil;
}

- (void)loadView
{
	// set up the base view
	CGRect frame = [[UIScreen mainScreen] applicationFrame];
	UIView *view = [[UIView alloc] initWithFrame:frame];
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	view.backgroundColor = [UIColor blackColor];
	view.autoresizesSubviews = YES;
	
	self.view = view;
	
	_minimumVisibleCenterWidth = 50.0f;
	_animationVelocityMaximum = 700.0f;
}

- (void)viewWillAppear:(BOOL)animated
{
	NSAssert(_centerPanelController, @"Must have a center panel controller");
	
	[super viewWillAppear:animated];
}

- (void)_updateUserInteractionEnabled
{
	DTSidePanelControllerPanel panel = [self presentedPanel];
	
	_leftBaseView.userInteractionEnabled = (panel == DTSidePanelControllerPanelLeft);
	_rightBaseView.userInteractionEnabled = (panel == DTSidePanelControllerPanelRight);
	_centerBaseView.userInteractionEnabled = (panel == DTSidePanelControllerPanelCenter);
}



- (void)_installTapToCloseGesture
{
	if (!_tapToCloseGesture)
	{
		_tapToCloseGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToClose:)];
		_tapToCloseGesture.numberOfTapsRequired = 1;
		_tapToCloseGesture.numberOfTouchesRequired = 1;
		_tapToCloseGesture.delegate = self;
	}
	
	[self.view addGestureRecognizer:_tapToCloseGesture];
}

- (void)_removeTapToCloseGesture
{
	[self.view removeGestureRecognizer:_tapToCloseGesture];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	CGPoint location = [touch locationInView:_centerBaseView];
	BOOL locationIsInCenterPanel = CGRectContainsPoint(_centerBaseView.bounds, location);
	
	if (gestureRecognizer == _centerPanelPanGesture)
	{
		return locationIsInCenterPanel;
	}
	
	if (gestureRecognizer ==_tapToCloseGesture)
	{
		return locationIsInCenterPanel;
	}
	
	return NO;
}

- (UIViewController *)_presentedPanelWithPosition:(CGPoint)position
{
	if (position.x > [self _centerPanelClosedPosition].x)
	{
		return _leftPanelController;
	}
	else if (position.x < [self _centerPanelClosedPosition].x)
	{
		return _rightPanelController;
	}
	else
	{
		return _centerPanelController;
	}
}

- (void)_addSubviewForPresentedPanel:(UIViewController *)panel
{
	_leftBaseView.hidden = (panel != _leftPanelController);
	_rightBaseView.hidden = (panel != _rightPanelController);
}

- (void)_updatePanelViewControllerPresentationBeforeAnimationForPosition:(CGPoint)position
{
	UIViewController *_targetPanel = [self _presentedPanelWithPosition:position];
	
	if (_presentedPanelViewController && _targetPanel != _presentedPanelViewController)
	{
		[_presentedPanelViewController willMoveToParentViewController:nil];
		
		[_presentedPanelViewController beginAppearanceTransition:NO animated:YES];
	}

	if (_targetPanel == _centerPanelController || _targetPanel == _presentedPanelViewController)
	{
		return;
	}
	
	[self addChildViewController:_targetPanel];
	
	[_targetPanel beginAppearanceTransition:YES animated:YES];
	
	[self _addSubviewForPresentedPanel:_targetPanel];
}

- (void)_updatePanelViewControllerPresentationAfterAnimationForPosition:(CGPoint)position
{
	UIViewController *_targetPanel = [self _presentedPanelWithPosition:position];
	
	if (_presentedPanelViewController && _targetPanel != _presentedPanelViewController)
	{
		[_presentedPanelViewController endAppearanceTransition];
		
		[_presentedPanelViewController didMoveToParentViewController:nil];

		_presentedPanelViewController = nil;
	}
	
	if (_targetPanel == _centerPanelController || _targetPanel == _presentedPanelViewController)
	{
		return;
	}
	
	[_targetPanel endAppearanceTransition];
	
	[_targetPanel didMoveToParentViewController:self];
	
	_presentedPanelViewController = _targetPanel;
}

- (void)_prepareViewControllerToBeShown:(UIViewController *)panel
{
	if (panel == _centerPanelController || _presentedPanelViewController == panel)
	{
		return;
	}
	
	[panel willMoveToParentViewController:self];
	
	[panel beginAppearanceTransition:YES animated:NO];
	
	[self _addSubviewForPresentedPanel:panel];
	
	[panel endAppearanceTransition];
	
	[panel didMoveToParentViewController:self];
	
	_presentedPanelViewController = panel;
}

- (void)_removePanelViewController:(UIViewController *)viewController notifyDidMove:(BOOL)notifyDidMove
{
	if (!viewController)
	{
		return;
	}
	
	[viewController willMoveToParentViewController:nil];
	
	[viewController beginAppearanceTransition:NO animated:NO];
	
	[viewController endAppearanceTransition];
	
	[viewController removeFromParentViewController];
	
	if (notifyDidMove)
	{
		[viewController didMoveToParentViewController:nil];
	}
}

#pragma mark - Calculations

- (CGFloat)_leftPanelVisibleWidth
{
	if (!_leftBaseView)
	{
		return 0.0f;
	}
	
	CGPoint center = [self _centerPanelClosedPosition];
	
	if (_centerBaseView.center.x <= center.x)
	{
		return 0.0f;
	}
	
	CGRect leftCoveredArea = CGRectIntersection(_centerBaseView.frame, _leftBaseView.frame);
	return _leftBaseView.bounds.size.width - leftCoveredArea.size.width;
}

- (CGFloat)_rightPanelVisibleWidth
{
	if (!_rightBaseView)
	{
		return 0.0f;
	}
	
	CGPoint center = [self _centerPanelClosedPosition];
	
	if (_centerBaseView.center.x >= center.x)
	{
		return 0.0f;
	}
	
	CGRect rightCoveredArea = CGRectIntersection(_centerBaseView.frame, _rightBaseView.frame);
	return _rightBaseView.bounds.size.width - rightCoveredArea.size.width;
}

- (CGFloat)_minCenterPanelPosition
{
	CGFloat minCenterX = (self.view.bounds.size.width/2.0f);
	
	if (_rightPanelController)
	{
		minCenterX -= [self _usedRightPanelWidth];
	}
	
	return minCenterX;
}

- (CGFloat)_maxCenterPanelPosition
{
	CGFloat maxCenterX = (self.view.bounds.size.width/2.0f);
	
	if (_leftPanelController)
	{
		maxCenterX += [self _usedLeftPanelWidth];
	}
	
	return maxCenterX;
}

- (CGPoint)_centerPanelPositionWithLeftPanelOpen
{
	return CGPointMake([self _maxCenterPanelPosition], _centerBaseView.center.y);
}

- (CGPoint)_centerPanelPositionWithRightPanelOpen
{
	return CGPointMake([self _minCenterPanelPosition], _centerBaseView.center.y);
}

- (CGPoint)_centerPanelClosedPosition
{
	return CGPointMake(self.view.bounds.size.width/2.0f, self.view.bounds.size.height/2.0f);
}

- (CGFloat)_usedLeftPanelWidth
{
	CGFloat usedWidth = _leftPanelWidth;
	CGFloat maxWidth = self.view.bounds.size.width - _minimumVisibleCenterWidth;
	
	if (usedWidth==0)
	{
		usedWidth = maxWidth;
	}
	else
	{
		usedWidth = MIN(maxWidth, usedWidth);
	}
	
	return usedWidth;
}

- (CGRect)_leftPanelFrame
{
	return CGRectMake(0, 0, [self _usedLeftPanelWidth], self.view.bounds.size.height);
}

- (CGFloat)_usedRightPanelWidth
{
	CGFloat usedWidth = _rightPanelWidth;
	CGFloat maxWidth = self.view.bounds.size.width - _minimumVisibleCenterWidth;
	
	if (usedWidth==0)
	{
		usedWidth = maxWidth;
	}
	else
	{
		usedWidth = MIN(maxWidth, usedWidth);
	}
	
	return usedWidth;
}

- (CGRect)_rightPanelFrame
{
	CGFloat usedWidth = [self _usedRightPanelWidth];

	return CGRectMake(self.view.bounds.size.width - usedWidth, 0, usedWidth, self.view.bounds.size.height);
}

#pragma mark - Animations

- (void)_updateTapToCloseGesture
{
	if (self.presentedPanel == DTSidePanelControllerPanelCenter)
	{
		[self _removeTapToCloseGesture];
	}
	else
	{
		[self _installTapToCloseGesture];
	}
}



- (void)_animateCenterPanelToPosition:(CGPoint)position withVelocity:(CGFloat)velocity
{
	CALayer *presentationlayer = _centerBaseView.layer.presentationLayer;
	CGPoint currentPosition = presentationlayer.position;
	
	CGFloat deltaX = position.x - currentPosition.x;


	CGFloat duration = deltaX / _animationVelocityMaximum;
	DTLogInfo(@"duration %1.1f", duration);

	_panelIsMoving = YES;

		[self _updatePanelViewControllerPresentationBeforeAnimationForPosition:position];

		[UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut animations:^{
			_centerBaseView.center = position;
		} completion:^(BOOL finished) {
			_panelIsMoving = NO;

			[self _updateTapToCloseGesture];
			[self _updatePanelViewControllerPresentationAfterAnimationForPosition:position];
			[self _updateUserInteractionEnabled];
		}];
}


- (void)_animateCenterPanelToRestingPositionWithVelocity:(CGFloat)velocity
{

	CGPoint endPosition = [self _centerPanelClosedPosition];

	if ([self _leftPanelVisibleWidth]>0)
	{
		if (velocity > 100.0f)
		{
			endPosition = [self _centerPanelPositionWithLeftPanelOpen];
		}
	} else if ([self _rightPanelVisibleWidth]>0)
	{
		if (velocity < 100.0f)
		{
			endPosition = [self _centerPanelPositionWithRightPanelOpen];
		}
	}

	[self _animateCenterPanelToPosition:endPosition withVelocity:velocity];

}

#pragma mark - Rotation

- (void)viewWillLayoutSubviews
{
	[super viewWillLayoutSubviews];
	
	if (!_panelIsMoving)
	{
		_panelToPresentAfterLayout = self.presentedPanel;
	}
}

- (void)viewDidLayoutSubviews
{
	if (!_panelIsMoving)
	{
		[self presentPanel:_panelToPresentAfterLayout animated:NO];
	}
	
	[_centerBaseView updateShadowPathToBounds:_centerBaseView.bounds withDuration:0.3];
	
	[super viewDidLayoutSubviews];
}

// iOS 6 autorotation
- (BOOL)shouldAutorotate
{
	if (_centerPanelController && ![_centerPanelController shouldAutorotate])
	{
		return NO;
	}

	if (_leftPanelController && ![_leftPanelController shouldAutorotate])
	{
		return NO;
	}

	if (_rightPanelController && ![_rightPanelController shouldAutorotate])
	{
		return NO;
	}
	
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
	NSUInteger orientations = UIInterfaceOrientationMaskAll;
	
	// only support the orientations that are also supported by all child VCs
	
	if (_centerPanelController)
	{
		orientations &= [_centerPanelController supportedInterfaceOrientations];
	}
	
	if (_leftPanelController)
	{
		orientations &= [_leftPanelController supportedInterfaceOrientations];
	}
	
	if (_rightPanelController)
	{
		orientations &= [_rightPanelController supportedInterfaceOrientations];
	}
	
	return orientations;
}

// iOS 5 autorotation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	if (_centerPanelController && ![_centerPanelController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation])
	{
		return NO;
	}

	if (_leftPanelController && ![_leftPanelController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation])
	{
		return NO;
	}

	if (_rightPanelController && ![_rightPanelController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation])
	{
		return NO;
	}

	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if (_centerPanelController)
	{
		[_centerPanelController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	}

	if (_leftPanelController)
	{
		[_leftPanelController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	}

	if (_rightPanelController)
	{
		[_rightPanelController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	if (_centerPanelController)
	{
		[_centerPanelController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	}
	
	if (_leftPanelController)
	{
		[_leftPanelController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	}
	
	if (_rightPanelController)
	{
		[_rightPanelController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	}
}


// need to forward this or else some navigation bars won't resize properly
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if (_centerPanelController)
	{
		[_centerPanelController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	}
	
	if (_leftPanelController)
	{
		[_leftPanelController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	}
	
	if (_rightPanelController)
	{
		[_rightPanelController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	}
}

- (BOOL)shouldAutomaticallyForwardRotationMethods
{
	return NO;
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
	return NO;
}

- (BOOL)automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers
{
	return NO;
}

#pragma mark - Actions

- (BOOL)_shouldAllowClosingOfPanel
{
	if ([_sidePanelDelegate respondsToSelector:@selector(sidePanelController:shouldAllowClosingOfSidePanel:)])
	{
		return [_sidePanelDelegate sidePanelController:self shouldAllowClosingOfSidePanel:[self presentedPanel]];
	}
	
	return YES;
}

- (void)tapToClose:(UITapGestureRecognizer *)gesture
{
	if (![self _shouldAllowClosingOfPanel])
	{
		return;
	}
	
	[self presentPanel:DTSidePanelControllerPanelCenter animated:YES];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture
{
	switch (gesture.state)
	{
		case UIGestureRecognizerStateBegan:
		{
			// for side panels ask delegate
			if ([self _presentedPanelWithPosition:_centerBaseView.center] != _centerPanelController && ![self _shouldAllowClosingOfPanel])
			{
				// cancel gesture
				gesture.enabled = NO;
				gesture.enabled = YES;
				
				return;
			}
			
			break;
		}
			
		case UIGestureRecognizerStateChanged:
		{
			CGPoint translation = [gesture translationInView:self.view];
			
			_lastTranslation = translation;

			CGPoint center = _centerBaseView.center;
			center.x += _lastTranslation.x;
			
			if (!_panelIsMoving)
			{
				UIViewController *panel = [self _presentedPanelWithPosition:center];
				
				if (!panel)
				{
					// cancel gesture
					gesture.enabled = NO;
					gesture.enabled = YES;
					
					// no panel in this direction
					return;
				}
				
				[self _prepareViewControllerToBeShown:panel];

				if (panel == _leftPanelController)
				{
					_minPanRange = [self _centerPanelClosedPosition];
					_maxPanRange = [self _centerPanelPositionWithLeftPanelOpen];
				}
				else if (panel == _rightPanelController)
				{
					_minPanRange = [self _centerPanelPositionWithRightPanelOpen];
					_maxPanRange = [self _centerPanelClosedPosition];
				}
				
				_panelIsMoving = YES;
			}
			
			// restrict to valid region
			center.x = MAX(MIN(_maxPanRange.x, center.x), _minPanRange.x);

			[gesture setTranslation:CGPointZero inView:self.view];
			
			[CATransaction begin];
			[CATransaction setDisableActions:YES];
			
			_centerBaseView.center = center;

			[CATransaction commit];
			break;
		}

		case UIGestureRecognizerStateCancelled:
		case UIGestureRecognizerStateEnded:
		{
			if (!_panelIsMoving)
			{
				return;
			}
			
			_panelIsMoving = NO;
			
			if (self.presentedPanel == DTSidePanelControllerPanelCenter)
			{
				[self _removePanelViewController:_presentedPanelViewController notifyDidMove:YES];
				_presentedPanelViewController = nil;
				return;
			}

			CGPoint velocity = [gesture velocityInView:self.view];
			DTLogInfo(@"velocity %@", NSStringFromCGPoint(velocity));
			[self _animateCenterPanelToRestingPositionWithVelocity:velocity.x];
			break;
		}
			
		default:
		{
			
		}
			break;
	}
}

#pragma mark - Public Interface

- (void)presentPanel:(DTSidePanelControllerPanel)panel animated:(BOOL)animated
{
	CGPoint targetPosition;
	
	_panelToPresentAfterLayout = panel;

	switch (panel)
	{
		case DTSidePanelControllerPanelLeft:
		{
			NSAssert(_leftBaseView, @"Cannot present a left panel if none is configured");

			if (_rightBaseView)
			{
				[self.view sendSubviewToBack:_rightBaseView];
			}
			
			targetPosition = [self _centerPanelPositionWithLeftPanelOpen];
			break;
		}
			
		case DTSidePanelControllerPanelCenter:
		{
			NSAssert(_centerBaseView, @"Cannot present a center panel if none is configured");

			targetPosition = [self _centerPanelClosedPosition];
			break;
		}

		case DTSidePanelControllerPanelRight:
		{
			NSAssert(_rightBaseView, @"Cannot present a right panel if none is configured");
			
			if (_leftBaseView)
			{
				[self.view sendSubviewToBack:_leftBaseView];
			}
			
			targetPosition = [self _centerPanelPositionWithRightPanelOpen];
			break;
		}
	}
	
	if (animated)
	{
		// uses minimum momentum for animation
		[self _animateCenterPanelToPosition:targetPosition withVelocity:_animationVelocityMaximum];
	}
	else
	{
		_centerBaseView.center = targetPosition;
	}
}

- (DTSidePanelControllerPanel)presentedPanel
{
	if ([self _leftPanelVisibleWidth]>0)
	{
		return DTSidePanelControllerPanelLeft;
	}
	
	if ([self _rightPanelVisibleWidth]>0)
	{
		return DTSidePanelControllerPanelRight;
	}
	
	return DTSidePanelControllerPanelCenter;
}

- (void)setWidth:(CGFloat)width forPanel:(DTSidePanelControllerPanel)panel animated:(BOOL)animated
{
	NSParameterAssert(panel != DTSidePanelControllerPanelCenter);
	
	switch (panel)
	{
		case DTSidePanelControllerPanelLeft:
		{
			_leftPanelWidth = width;
			break;
		}
			
		case DTSidePanelControllerPanelRight:
		{
			_rightPanelWidth = width;
			break;
		}
			
		case DTSidePanelControllerPanelCenter:
		{
			DTLogError(@"Setting width for center panel not supported");
			break;
		}
	}

	CGFloat duration = animated?0.3:0;
	
	[UIView animateWithDuration:duration animations:^{
		_leftBaseView.frame = [self _leftPanelFrame];
		_rightBaseView.frame = [self _rightPanelFrame];
	}];

}

#pragma mark - Properties

- (void)setCenterPanelController:(UIViewController *)centerPanelController
{
	if (centerPanelController == _centerPanelController)
	{
		return;
	}
	
	_centerPanelController.sidePanelController = nil;
	[self _removePanelViewController:_centerPanelController notifyDidMove:NO];
	
	_centerPanelController = centerPanelController;
	_centerPanelController.sidePanelController = self;
	
	if (!_centerBaseView)
	{
		_centerBaseView = [[UIView alloc] initWithFrame:self.view.bounds];
		_centerBaseView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.view addSubview:_centerBaseView];
		
		[_centerBaseView addShadowWithColor:[UIColor blackColor] alpha:1 radius:6 offset:CGSizeZero];
		
		_centerPanelPanGesture = [[DTSidePanelPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
		_centerPanelPanGesture.delegate = self;
		[self.view addGestureRecognizer:_centerPanelPanGesture];
	}
	
	//[self _sortPanels];
	
	[self addChildViewController:_centerPanelController];
	
	[_centerPanelController beginAppearanceTransition:YES animated:NO];
	_centerPanelController.view.frame = _centerBaseView.bounds;
	[_centerBaseView addSubview:_centerPanelController.view];
	[_centerPanelController endAppearanceTransition];
	
	[_centerPanelController didMoveToParentViewController:self];
}

- (void)setLeftPanelController:(UIViewController *)leftPanelController
{
	if (leftPanelController == _leftPanelController)
	{
		return;
	}
	
	_leftPanelController.sidePanelController = nil;
	[self _removePanelViewController:_leftPanelController notifyDidMove:NO];

	_leftPanelController = leftPanelController;
	_leftPanelController.sidePanelController = self;

	_leftBaseView = [[UIView alloc] initWithFrame:[self _leftPanelFrame]];
	_leftBaseView.userInteractionEnabled = NO;
	[self.view addSubview:_leftBaseView];
	[self.view sendSubviewToBack:_leftBaseView];
	_leftPanelController.view.frame = _leftBaseView.frame;
	[_leftBaseView addSubview:leftPanelController.view];


}

- (void)setRightPanelController:(UIViewController *)rightPanelController
{
	if (rightPanelController == _rightPanelController)
	{
		return;
	}
	
	_rightPanelController.sidePanelController = nil;
	[self _removePanelViewController:_rightPanelController notifyDidMove:NO];
	
	_rightPanelController = rightPanelController;
	_rightPanelController.sidePanelController = self;

	_rightBaseView = [[UIView alloc] initWithFrame:[self _rightPanelFrame]];
	_rightBaseView.userInteractionEnabled = NO;
	[self.view addSubview:_rightBaseView];
	[self.view sendSubviewToBack:_rightBaseView];
	_rightPanelController.view.frame = _leftBaseView.frame;

	[_rightBaseView addSubview:_rightPanelController.view];

}


@end
