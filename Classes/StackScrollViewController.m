/*
 This module is licenced under the BSD license.
 
 Copyright (C) 2011 by raw engineering <nikhil.jain (at) raweng (dot) com, reefaq.mohammed (at) raweng (dot) com>.
 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
//
//  StackScrollViewController.m
//  SlidingView
//
//  Created by Reefaq on 2/24/11.
//  Copyright 2011 raw engineering . All rights reserved.
//

#import "StackScrollViewController.h"
#import "UIViewWithShadow.h"

const NSInteger SLIDE_VIEWS_MINUS_X_POSITION = -130;
const NSInteger SLIDE_VIEWS_START_X_POS = 0;

@implementation StackScrollViewController

@synthesize slideViews, borderViews, viewControllersStack, slideStartPosition;

-(id)init {
	
	if(self= [super init]) {
		
		viewControllersStack = [[NSMutableArray alloc] init]; 
		borderViews = [[UIView alloc] initWithFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION - 2, -2, 2, self.view.frame.size.height)];
		[borderViews setBackgroundColor:[UIColor clearColor]];
		UIView* verticalLineView1 = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, borderViews.frame.size.height)] autorelease];
		[verticalLineView1 setBackgroundColor:[UIColor whiteColor]];
		[verticalLineView1 setTag:1];
		[verticalLineView1 setHidden:TRUE];
		[borderViews addSubview:verticalLineView1];
		
		UIView* verticalLineView2 = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, borderViews.frame.size.height)] autorelease];
		[verticalLineView2 setBackgroundColor:[UIColor grayColor]];
		[verticalLineView2 setTag:2];
		[verticalLineView2 setHidden:TRUE];		
		[borderViews addSubview:verticalLineView2];
		
		[self.view addSubview:borderViews];
		
		slideViews = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
		[slideViews setBackgroundColor:[UIColor clearColor]];
		[self.view setBackgroundColor:[UIColor clearColor]];
		[self.view setFrame:slideViews.frame];
		self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		viewXPosition = 0;
		lastTouchPoint = -1;
		
		dragDirection = [[NSString alloc] init];
		dragDirection = @"";
		
		viewAtLeft2=nil;
		viewAtLeft=nil;
		viewAtRight=nil;
		viewAtRight2=nil;
		viewAtRightAtTouchBegan = nil;
		
		UIPanGestureRecognizer* panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
		[panRecognizer setMaximumNumberOfTouches:1];
		[panRecognizer setDelaysTouchesBegan:TRUE];
		[panRecognizer setDelaysTouchesEnded:TRUE];
		[panRecognizer setCancelsTouchesInView:TRUE];
		[self.view addGestureRecognizer:panRecognizer];
		[panRecognizer release];
		
		[self.view addSubview:slideViews];
		
	}
	
	return self;
}

-(void)arrangeVerticalBar {
	
	if ([[slideViews subviews] count] > 2) {
		[[borderViews viewWithTag:2] setHidden:TRUE];
		[[borderViews viewWithTag:1] setHidden:TRUE];
		NSInteger stackCount = 0;
		if (viewAtLeft != nil ) {
			stackCount = [[slideViews subviews] indexOfObject:viewAtLeft];
		}
		
		if (viewAtLeft != nil && viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION) {
			stackCount += 1;
		}
		
		if (stackCount == 2) {
			[[borderViews viewWithTag:2] setHidden:FALSE];
		}
		if (stackCount >= 3) {
			[[borderViews viewWithTag:2] setHidden:FALSE];
			[[borderViews viewWithTag:1] setHidden:FALSE];
		}
		
		
	}
}


- (void)handlePanFrom:(UIPanGestureRecognizer *)recognizer {
	
	CGPoint translatedPoint = [recognizer translationInView:self.view];
	
	if (recognizer.state == UIGestureRecognizerStateBegan) {
		displacementPosition = 0;
		positionOfViewAtRightAtTouchBegan = viewAtRight.frame.origin;
		positionOfViewAtLeftAtTouchBegan = viewAtLeft.frame.origin;
		viewAtRightAtTouchBegan = viewAtRight;
		viewAtLeftAtTouchBegan = viewAtLeft;
		[viewAtLeft.layer removeAllAnimations];
		[viewAtRight.layer removeAllAnimations];
		[viewAtRight2.layer removeAllAnimations];
		[viewAtLeft2.layer removeAllAnimations];
		if (viewAtLeft2 != nil) {
			NSInteger viewAtLeft2Position = [[slideViews subviews] indexOfObject:viewAtLeft2];
			if (viewAtLeft2Position > 0) {
				[((UIView*)[[slideViews subviews] objectAtIndex:viewAtLeft2Position -1]) setHidden:FALSE];
			}
		}
		
		[self arrangeVerticalBar];
	}
	
	
	CGPoint location =  [recognizer locationInView:self.view];
	
	if (lastTouchPoint != -1) {
		
		if (location.x < lastTouchPoint) {			
			
			if ([dragDirection isEqualToString:@"RIGHT"]) {
				positionOfViewAtRightAtTouchBegan = viewAtRight.frame.origin;
				positionOfViewAtLeftAtTouchBegan = viewAtLeft.frame.origin;
				displacementPosition = translatedPoint.x * -1;
			}				
			
			dragDirection = @"LEFT";
			
			if (viewAtRight != nil) {
				
				if (viewAtLeft.frame.origin.x <= SLIDE_VIEWS_MINUS_X_POSITION) {						
					if ([[slideViews subviews] indexOfObject:viewAtRight] < ([[slideViews subviews] count]-1)) {
						viewAtLeft2 = viewAtLeft;
						viewAtLeft = viewAtRight;
						[viewAtRight2 setHidden:FALSE];
						viewAtRight = viewAtRight2;
						if ([[slideViews subviews] indexOfObject:viewAtRight] < ([[slideViews subviews] count]-1)) {
							viewAtRight2 = [[slideViews subviews] objectAtIndex:[[slideViews subviews] indexOfObject:viewAtRight] + 1];
						}else {
							viewAtRight2 = nil;
						}							
						positionOfViewAtRightAtTouchBegan = viewAtRight.frame.origin;
						positionOfViewAtLeftAtTouchBegan = viewAtLeft.frame.origin;
						displacementPosition = translatedPoint.x * -1;							
						if ([[slideViews subviews] indexOfObject:viewAtLeft2] > 1) {
							[[[slideViews subviews] objectAtIndex:[[slideViews subviews] indexOfObject:viewAtLeft2] - 2] setHidden:TRUE];
						}
						
					}
					
				}
				
				if (viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION && viewAtRight.frame.origin.x + viewAtRight.frame.size.width > self.view.frame.size.width) {
					if ((positionOfViewAtRightAtTouchBegan.x + translatedPoint.x + displacementPosition + viewAtRight.frame.size.width) <= self.view.frame.size.width) {
						[viewAtRight setFrame:CGRectMake(self.view.frame.size.width - viewAtRight.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					}else {
						[viewAtRight setFrame:CGRectMake(positionOfViewAtRightAtTouchBegan.x + translatedPoint.x + displacementPosition, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					}
					
				}
				else if (([[slideViews subviews] indexOfObject:viewAtRight] == [[slideViews subviews] count]-1) && viewAtRight.frame.origin.x <= (self.view.frame.size.width - viewAtRight.frame.size.width)) {
					if ((positionOfViewAtRightAtTouchBegan.x + translatedPoint.x + displacementPosition) <= SLIDE_VIEWS_MINUS_X_POSITION) {
						[viewAtRight setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					}else {
						[viewAtRight setFrame:CGRectMake(positionOfViewAtRightAtTouchBegan.x + translatedPoint.x + displacementPosition, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					}
				}
				else{						
					if (positionOfViewAtLeftAtTouchBegan.x + translatedPoint.x + displacementPosition <= SLIDE_VIEWS_MINUS_X_POSITION) {
						[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
					}else {
						[viewAtLeft setFrame:CGRectMake(positionOfViewAtLeftAtTouchBegan.x + translatedPoint.x + displacementPosition , viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
					}						
					[viewAtRight setFrame:CGRectMake(viewAtLeft.frame.origin.x + viewAtLeft.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					
					if (viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION) {
						positionOfViewAtRightAtTouchBegan = viewAtRight.frame.origin;
						positionOfViewAtLeftAtTouchBegan = viewAtLeft.frame.origin;
						displacementPosition = translatedPoint.x * -1;
					}
					
				}
				
			}else {
				[viewAtLeft setFrame:CGRectMake(positionOfViewAtLeftAtTouchBegan.x + translatedPoint.x + displacementPosition , viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
			}
			
			[self arrangeVerticalBar];
			
		}else if (location.x > lastTouchPoint) {	
			
			if ([dragDirection isEqualToString:@"LEFT"]) {
				positionOfViewAtRightAtTouchBegan = viewAtRight.frame.origin;
				positionOfViewAtLeftAtTouchBegan = viewAtLeft.frame.origin;
				displacementPosition = translatedPoint.x;
			}	
			
			dragDirection = @"RIGHT";
			
			if (viewAtLeft != nil) {
				
				if (viewAtRight.frame.origin.x >= self.view.frame.size.width) {
					
					if ([[slideViews subviews] indexOfObject:viewAtLeft] > 0) {							
						[viewAtRight2 setHidden:TRUE];
						viewAtRight2 = viewAtRight;
						viewAtRight = viewAtLeft;
						viewAtLeft = viewAtLeft2;						
						if ([[slideViews subviews] indexOfObject:viewAtLeft] > 0) {
							viewAtLeft2 = [[slideViews subviews] objectAtIndex:[[slideViews subviews] indexOfObject:viewAtLeft] - 1];
							[viewAtLeft2 setHidden:FALSE];
						}
						else{
							viewAtLeft2 = nil;
						}
						positionOfViewAtRightAtTouchBegan = viewAtRight.frame.origin;
						positionOfViewAtLeftAtTouchBegan = viewAtLeft.frame.origin;
						displacementPosition = translatedPoint.x;
						
						[self arrangeVerticalBar];
					}
				}
				
				if((viewAtRight.frame.origin.x < (viewAtLeft.frame.origin.x + viewAtLeft.frame.size.width)) && viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION){						
					if ((positionOfViewAtRightAtTouchBegan.x + translatedPoint.x - displacementPosition) >= (viewAtLeft.frame.origin.x + viewAtLeft.frame.size.width)) {
						[viewAtRight setFrame:CGRectMake(viewAtLeft.frame.origin.x + viewAtLeft.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					}else {
						[viewAtRight setFrame:CGRectMake(positionOfViewAtRightAtTouchBegan.x + translatedPoint.x - displacementPosition, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					}
					
				}
				else if ([[slideViews subviews] indexOfObject:viewAtLeft] == 0) {
					if (viewAtRight == nil) {
						[viewAtLeft setFrame:CGRectMake(positionOfViewAtLeftAtTouchBegan.x + translatedPoint.x - displacementPosition, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
					}
					else{
						[viewAtRight setFrame:CGRectMake(positionOfViewAtRightAtTouchBegan.x + translatedPoint.x - displacementPosition, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
						if (viewAtRight.frame.origin.x - viewAtLeft.frame.size.width < SLIDE_VIEWS_MINUS_X_POSITION) {
							[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
						}else{
							[viewAtLeft setFrame:CGRectMake(viewAtRight.frame.origin.x - viewAtLeft.frame.size.width, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
						}
					}
				}					
				else{
					if ((positionOfViewAtRightAtTouchBegan.x + translatedPoint.x - displacementPosition) >= self.view.frame.size.width) {
						[viewAtRight setFrame:CGRectMake(self.view.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					}else {
						[viewAtRight setFrame:CGRectMake(positionOfViewAtRightAtTouchBegan.x + translatedPoint.x - displacementPosition, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					}
					if (viewAtRight.frame.origin.x - viewAtLeft.frame.size.width < SLIDE_VIEWS_MINUS_X_POSITION) {
						[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
					}
					else{
						[viewAtLeft setFrame:CGRectMake(viewAtRight.frame.origin.x - viewAtLeft.frame.size.width, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
					}
					if (viewAtRight.frame.origin.x >= self.view.frame.size.width) {
						positionOfViewAtRightAtTouchBegan = viewAtRight.frame.origin;
						positionOfViewAtLeftAtTouchBegan = viewAtLeft.frame.origin;
						displacementPosition = translatedPoint.x;
					}
					
					[self arrangeVerticalBar];
				}
				
			}
			
			[self arrangeVerticalBar];
		}
	}
	
	lastTouchPoint = location.x;
	
	// STATE END	
	if (recognizer.state == UIGestureRecognizerStateEnded) {
		
		if ([dragDirection isEqualToString:@"LEFT"]) {
			if (viewAtRight != nil) {
				if ([[slideViews subviews] indexOfObject:viewAtLeft] == 0 && !(viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION || viewAtLeft.frame.origin.x == SLIDE_VIEWS_START_X_POS)) {
					[UIView beginAnimations:nil context:NULL];
					[UIView setAnimationDuration:0.2];
					[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:nil cache:YES];
					[UIView setAnimationBeginsFromCurrentState:YES];
					if (viewAtLeft.frame.origin.x < SLIDE_VIEWS_START_X_POS && viewAtRight != nil) {
						[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
						[viewAtRight setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION + viewAtLeft.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width,viewAtRight.frame.size.height)];
					}
					else{
						
						//Drop Card View Animation
						if ((((UIView*)[[slideViews subviews] objectAtIndex:0]).frame.origin.x+200) >= (self.view.frame.origin.x + ((UIView*)[[slideViews subviews] objectAtIndex:0]).frame.size.width)) {
							
							NSInteger viewControllerCount = [viewControllersStack count];
							
							if (viewControllerCount > 1) {
								for (int i = 1; i < viewControllerCount; i++) {
									viewXPosition = self.view.frame.size.width - [slideViews viewWithTag:i].frame.size.width;
									[[slideViews viewWithTag:i] removeFromSuperview];
									[viewControllersStack removeLastObject];
								}
								
								[[borderViews viewWithTag:3] setHidden:TRUE];
								[[borderViews viewWithTag:2] setHidden:TRUE];
								[[borderViews viewWithTag:1] setHidden:TRUE];
								
							}
							
							// Removes the selection of row for the first slide view
							for (UIView* tableView in [[[slideViews subviews] objectAtIndex:0] subviews]) {
								if([tableView isKindOfClass:[UITableView class]]){
									NSIndexPath* selectedRow =  [(UITableView*)tableView indexPathForSelectedRow];
									NSArray *indexPaths = [NSArray arrayWithObjects:selectedRow, nil];
									[(UITableView*)tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:NO];
								}
							}
							viewAtLeft2 = nil;
							viewAtRight = nil;
							viewAtRight2 = nil;							 
						}
						
						[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_START_X_POS, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
						if (viewAtRight != nil) {
							[viewAtRight setFrame:CGRectMake(SLIDE_VIEWS_START_X_POS + viewAtLeft.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width,viewAtRight.frame.size.height)];						
						}
						
					}
					[UIView commitAnimations];
				}
				else if (viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION && viewAtRight.frame.origin.x + viewAtRight.frame.size.width > self.view.frame.size.width) {
					[UIView beginAnimations:nil context:NULL];
					[UIView setAnimationDuration:0.2];
					[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:nil cache:YES];
					[UIView setAnimationBeginsFromCurrentState:YES];
					[viewAtRight setFrame:CGRectMake(self.view.frame.size.width - viewAtRight.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width,viewAtRight.frame.size.height)];						
					[UIView commitAnimations];						
				}	
				else if (viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION && viewAtRight.frame.origin.x + viewAtRight.frame.size.width < self.view.frame.size.width) {
					[UIView beginAnimations:@"RIGHT-WITH-RIGHT" context:NULL];
					[UIView setAnimationDuration:0.2];
					[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:nil cache:YES];
					[UIView setAnimationBeginsFromCurrentState:YES];
					[viewAtRight setFrame:CGRectMake(self.view.frame.size.width - viewAtRight.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width,viewAtRight.frame.size.height)];
					[UIView setAnimationDelegate:self];
					[UIView setAnimationDidStopSelector:@selector(bounceBack:finished:context:)];
					[UIView commitAnimations];
				}
				else if (viewAtLeft.frame.origin.x > SLIDE_VIEWS_MINUS_X_POSITION) {
					[UIView setAnimationDuration:0.2];
					[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:nil cache:YES];
					[UIView setAnimationBeginsFromCurrentState:YES];
					if ((viewAtLeft.frame.origin.x + viewAtLeft.frame.size.width > self.view.frame.size.width) && viewAtLeft.frame.origin.x < (self.view.frame.size.width - (viewAtLeft.frame.size.width)/2)) {
						[UIView beginAnimations:@"LEFT-WITH-LEFT" context:nil];
						[viewAtLeft setFrame:CGRectMake(self.view.frame.size.width - viewAtLeft.frame.size.width, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
						
						//Show bounce effect
						[viewAtRight setFrame:CGRectMake(self.view.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width,viewAtRight.frame.size.height)];						
					}
					else {
						[UIView beginAnimations:@"LEFT-WITH-RIGHT" context:nil];	
						[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
						if (positionOfViewAtLeftAtTouchBegan.x + viewAtLeft.frame.size.width <= self.view.frame.size.width) {
							[viewAtRight setFrame:CGRectMake((self.view.frame.size.width - viewAtRight.frame.size.width), viewAtRight.frame.origin.y, viewAtRight.frame.size.width,viewAtRight.frame.size.height)];						
						}
						else{
							[viewAtRight setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION + viewAtLeft.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width,viewAtRight.frame.size.height)];						
						}
						
						//Show bounce effect
						[viewAtRight2 setFrame:CGRectMake(viewAtRight.frame.origin.x + viewAtRight.frame.size.width, viewAtRight2.frame.origin.y, viewAtRight2.frame.size.width, viewAtRight2.frame.size.height)];
					}
					[UIView setAnimationDelegate:self];
					[UIView setAnimationDidStopSelector:@selector(bounceBack:finished:context:)];
					[UIView commitAnimations];
				}
				
			}
			else{
				[UIView beginAnimations:nil context:NULL];
				[UIView setAnimationDuration:0.2];
				[UIView setAnimationBeginsFromCurrentState:YES];
				[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:nil cache:YES];
				[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_START_X_POS, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
				[UIView commitAnimations];
			}
			
		}else if ([dragDirection isEqualToString:@"RIGHT"]) {
			if (viewAtLeft != nil) {
				if ([[slideViews subviews] indexOfObject:viewAtLeft] == 0 && !(viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION || viewAtLeft.frame.origin.x == SLIDE_VIEWS_START_X_POS)) {
					[UIView beginAnimations:nil context:NULL];
					[UIView setAnimationDuration:0.2];			
					[UIView setAnimationBeginsFromCurrentState:YES];
					[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:nil cache:YES];
					if (viewAtLeft.frame.origin.x > SLIDE_VIEWS_MINUS_X_POSITION || viewAtRight == nil) {
						
						//Drop Card View Animation
						if ((((UIView*)[[slideViews subviews] objectAtIndex:0]).frame.origin.x+200) >= (self.view.frame.origin.x + ((UIView*)[[slideViews subviews] objectAtIndex:0]).frame.size.width)) {
							NSInteger viewControllerCount = [viewControllersStack count];
							if (viewControllerCount > 1) {
								for (int i = 1; i < viewControllerCount; i++) {
									viewXPosition = self.view.frame.size.width - [slideViews viewWithTag:i].frame.size.width;
									[[slideViews viewWithTag:i] removeFromSuperview];
									[viewControllersStack removeLastObject];
								}
								[[borderViews viewWithTag:3] setHidden:TRUE];
								[[borderViews viewWithTag:2] setHidden:TRUE];
								[[borderViews viewWithTag:1] setHidden:TRUE];
							}
							
							// Removes the selection of row for the first slide view
							for (UIView* tableView in [[[slideViews subviews] objectAtIndex:0] subviews]) {
								if([tableView isKindOfClass:[UITableView class]]){
									NSIndexPath* selectedRow =  [(UITableView*)tableView indexPathForSelectedRow];
									NSArray *indexPaths = [NSArray arrayWithObjects:selectedRow, nil];
									[(UITableView*)tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:NO];
								}
							}
							
							viewAtLeft2 = nil;
							viewAtRight = nil;
							viewAtRight2 = nil;							 
						}
						[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_START_X_POS, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
						if (viewAtRight != nil) {
							[viewAtRight setFrame:CGRectMake(SLIDE_VIEWS_START_X_POS + viewAtLeft.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width,viewAtRight.frame.size.height)];
						}
					}
					else{
						[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
						[viewAtRight setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION + viewAtLeft.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width,viewAtRight.frame.size.height)];
					}
					[UIView commitAnimations];
				}
				else if (viewAtRight.frame.origin.x < self.view.frame.size.width) {
					if((viewAtRight.frame.origin.x < (viewAtLeft.frame.origin.x + viewAtLeft.frame.size.width)) && viewAtRight.frame.origin.x < (self.view.frame.size.width - (viewAtRight.frame.size.width/2))){
						[UIView beginAnimations:@"RIGHT-WITH-RIGHT" context:NULL];
						[UIView setAnimationDuration:0.2];
						[UIView setAnimationBeginsFromCurrentState:YES];
						[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:nil cache:YES];
						[viewAtRight setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION + viewAtLeft.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width,viewAtRight.frame.size.height)];						
						[UIView setAnimationDelegate:self];
						[UIView setAnimationDidStopSelector:@selector(bounceBack:finished:context:)];
						[UIView commitAnimations];
					}				
					else{
						
						[UIView beginAnimations:@"RIGHT-WITH-LEFT" context:NULL];
						[UIView setAnimationDuration:0.2];
						[UIView setAnimationBeginsFromCurrentState:YES];
						[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:nil cache:YES];
						if([[slideViews subviews] indexOfObject:viewAtLeft] > 0){ 
							if (positionOfViewAtRightAtTouchBegan.x  + viewAtRight.frame.size.width <= self.view.frame.size.width) {							
								[viewAtLeft setFrame:CGRectMake(self.view.frame.size.width - viewAtLeft.frame.size.width, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
							}
							else{							
								[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION + viewAtLeft2.frame.size.width, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
							}
							[viewAtRight setFrame:CGRectMake(self.view.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width,viewAtRight.frame.size.height)];		
						}
						else{
							[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
							[viewAtRight setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION + viewAtLeft.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width,viewAtRight.frame.size.height)];
						}
						[UIView setAnimationDelegate:self];
						[UIView setAnimationDidStopSelector:@selector(bounceBack:finished:context:)];
						[UIView commitAnimations];
					}
					
				}
			}			
		}
		lastTouchPoint = -1;
		dragDirection = @"";
	}	
	
}

- (void)bounceBack:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {	
	
	BOOL isBouncing = FALSE;
	
	if([dragDirection isEqualToString:@""] && [finished boolValue]){
		[viewAtLeft.layer removeAllAnimations];
		[viewAtRight.layer removeAllAnimations];
		[viewAtRight2.layer removeAllAnimations];
		[viewAtLeft2.layer removeAllAnimations];
            if ([animationID isEqualToString:@"LEFT-WITH-LEFT"] && viewAtLeft2.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION) {
                CABasicAnimation *bounceAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
                bounceAnimation.duration = 0.2;
                bounceAnimation.fromValue = [NSNumber numberWithFloat:viewAtLeft.center.x];
                bounceAnimation.toValue = [NSNumber numberWithFloat:viewAtLeft.center.x -10];
                bounceAnimation.repeatCount = 0;
                bounceAnimation.autoreverses = YES;
                bounceAnimation.fillMode = kCAFillModeBackwards;
                bounceAnimation.removedOnCompletion = YES;
                bounceAnimation.additive = NO;
                [viewAtLeft.layer addAnimation:bounceAnimation forKey:@"bounceAnimation"];
                
                [viewAtRight setHidden:FALSE];
                CABasicAnimation *bounceAnimationForRight = [CABasicAnimation animationWithKeyPath:@"position.x"];
                bounceAnimationForRight.duration = 0.2;
                bounceAnimationForRight.fromValue = [NSNumber numberWithFloat:viewAtRight.center.x];
                bounceAnimationForRight.toValue = [NSNumber numberWithFloat:viewAtRight.center.x - 20];
                bounceAnimationForRight.repeatCount = 0;
                bounceAnimationForRight.autoreverses = YES;
                bounceAnimationForRight.fillMode = kCAFillModeBackwards;
                bounceAnimationForRight.removedOnCompletion = YES;
                bounceAnimationForRight.additive = NO;
                [viewAtRight.layer addAnimation:bounceAnimationForRight forKey:@"bounceAnimationRight"];
            }else if ([animationID isEqualToString:@"LEFT-WITH-RIGHT"]  && viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION) {
                CABasicAnimation *bounceAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
                bounceAnimation.duration = 0.2;
                bounceAnimation.fromValue = [NSNumber numberWithFloat:viewAtRight.center.x];
                bounceAnimation.toValue = [NSNumber numberWithFloat:viewAtRight.center.x - 10];
                bounceAnimation.repeatCount = 0;
                bounceAnimation.autoreverses = YES;
                bounceAnimation.fillMode = kCAFillModeBackwards;
                bounceAnimation.removedOnCompletion = YES;
                bounceAnimation.additive = NO;
                [viewAtRight.layer addAnimation:bounceAnimation forKey:@"bounceAnimation"];
                
                
                [viewAtRight2 setHidden:FALSE];
                CABasicAnimation *bounceAnimationForRight2 = [CABasicAnimation animationWithKeyPath:@"position.x"];
                bounceAnimationForRight2.duration = 0.2;
                bounceAnimationForRight2.fromValue = [NSNumber numberWithFloat:viewAtRight2.center.x];
                bounceAnimationForRight2.toValue = [NSNumber numberWithFloat:viewAtRight2.center.x - 20];
                bounceAnimationForRight2.repeatCount = 0;
                bounceAnimationForRight2.autoreverses = YES;
                bounceAnimationForRight2.fillMode = kCAFillModeBackwards;
                bounceAnimationForRight2.removedOnCompletion = YES;
                bounceAnimationForRight2.additive = NO;
                [viewAtRight2.layer addAnimation:bounceAnimationForRight2 forKey:@"bounceAnimationRight2"];
            }else if ([animationID isEqualToString:@"RIGHT-WITH-RIGHT"]) {
                CABasicAnimation *bounceAnimationLeft = [CABasicAnimation animationWithKeyPath:@"position.x"];
                bounceAnimationLeft.duration = 0.2;
                bounceAnimationLeft.fromValue = [NSNumber numberWithFloat:viewAtLeft.center.x];
                bounceAnimationLeft.toValue = [NSNumber numberWithFloat:viewAtLeft.center.x + 10];
                bounceAnimationLeft.repeatCount = 0;
                bounceAnimationLeft.autoreverses = YES;
                bounceAnimationLeft.fillMode = kCAFillModeBackwards;
                bounceAnimationLeft.removedOnCompletion = YES;
                bounceAnimationLeft.additive = NO;
                [viewAtLeft.layer addAnimation:bounceAnimationLeft forKey:@"bounceAnimationLeft"];
                
                CABasicAnimation *bounceAnimationRight = [CABasicAnimation animationWithKeyPath:@"position.x"];
                bounceAnimationRight.duration = 0.2;
                bounceAnimationRight.fromValue = [NSNumber numberWithFloat:viewAtRight.center.x];
                bounceAnimationRight.toValue = [NSNumber numberWithFloat:viewAtRight.center.x + 10];
                bounceAnimationRight.repeatCount = 0;
                bounceAnimationRight.autoreverses = YES;
                bounceAnimationRight.fillMode = kCAFillModeBackwards;
                bounceAnimationRight.removedOnCompletion = YES;
                bounceAnimationRight.additive = NO;
                [viewAtRight.layer addAnimation:bounceAnimationRight forKey:@"bounceAnimationRight"];
                
            }else if ([animationID isEqualToString:@"RIGHT-WITH-LEFT"]) {
                CABasicAnimation *bounceAnimationLeft = [CABasicAnimation animationWithKeyPath:@"position.x"];
                bounceAnimationLeft.duration = 0.2;
                bounceAnimationLeft.fromValue = [NSNumber numberWithFloat:viewAtLeft.center.x];
                bounceAnimationLeft.toValue = [NSNumber numberWithFloat:viewAtLeft.center.x + 10];
                bounceAnimationLeft.repeatCount = 0;
                bounceAnimationLeft.autoreverses = YES;
                bounceAnimationLeft.fillMode = kCAFillModeBackwards;
                bounceAnimationLeft.removedOnCompletion = YES;
                bounceAnimationLeft.additive = NO;
                [viewAtLeft.layer addAnimation:bounceAnimationLeft forKey:@"bounceAnimationLeft"];
                
                if (viewAtLeft2 != nil) {
                    [viewAtLeft2 setHidden:FALSE];
                    NSInteger viewAtLeft2Position = [[slideViews subviews] indexOfObject:viewAtLeft2];
                    if (viewAtLeft2Position > 0) {
                        [((UIView*)[[slideViews subviews] objectAtIndex:viewAtLeft2Position -1]) setHidden:FALSE];
                    }
                    CABasicAnimation* bounceAnimationLeft2 = [CABasicAnimation animationWithKeyPath:@"position.x"];
                    bounceAnimationLeft2.duration = 0.2;
                    bounceAnimationLeft2.fromValue = [NSNumber numberWithFloat:viewAtLeft2.center.x];
                    bounceAnimationLeft2.toValue = [NSNumber numberWithFloat:viewAtLeft2.center.x + 10];
                    bounceAnimationLeft2.repeatCount = 0;
                    bounceAnimationLeft2.autoreverses = YES;
                    bounceAnimationLeft2.fillMode = kCAFillModeBackwards;
                    bounceAnimationLeft2.removedOnCompletion = YES;
                    bounceAnimationLeft2.additive = NO;
                    [viewAtLeft2.layer addAnimation:bounceAnimationLeft2 forKey:@"bounceAnimationviewAtLeft2"];
                    [self performSelector:@selector(callArrangeVerticalBar) withObject:nil afterDelay:0.4];
                    isBouncing = TRUE;
                }
                
            }
		
	}
	[self arrangeVerticalBar];	
	if ([[slideViews subviews] indexOfObject:viewAtLeft2] == 1 && isBouncing) {
		[[borderViews viewWithTag:2] setHidden:TRUE];
	}
}


- (void)callArrangeVerticalBar{
	[self arrangeVerticalBar];
}

- (void)loadView {
	[super loadView];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)addViewInSlider:(UIViewController*)controller invokeByController:(UIViewController*)invokeByController isStackStartView:(BOOL)isStackStartView{
		
	if (isStackStartView) {
		slideStartPosition = SLIDE_VIEWS_START_X_POS;
		viewXPosition = slideStartPosition;
		
		for (UIView* subview in [slideViews subviews]) {
			[subview removeFromSuperview];
		}
		
		[[borderViews viewWithTag:3] setHidden:TRUE];
		[[borderViews viewWithTag:2] setHidden:TRUE];
		[[borderViews viewWithTag:1] setHidden:TRUE];
		[viewControllersStack removeAllObjects];
	}
	
	
	if([viewControllersStack count] > 1){
		NSInteger indexOfViewController = [viewControllersStack
										   indexOfObject:invokeByController]+1;
		
		if ([invokeByController parentViewController]) {
			indexOfViewController = [viewControllersStack
									 indexOfObject:[invokeByController parentViewController]]+1;
		}
		
		NSInteger viewControllerCount = [viewControllersStack count];
		for (int i = indexOfViewController; i < viewControllerCount; i++) {
			[[slideViews viewWithTag:i] removeFromSuperview];
			[viewControllersStack removeObjectAtIndex:indexOfViewController];
			viewXPosition = self.view.frame.size.width - [controller view].frame.size.width;
		}
	}else if([viewControllersStack count] == 0) {
		for (UIView* subview in [slideViews subviews]) {
			[subview removeFromSuperview];
		}		[viewControllersStack removeAllObjects];
		[[borderViews viewWithTag:3] setHidden:TRUE];
		[[borderViews viewWithTag:2] setHidden:TRUE];
		[[borderViews viewWithTag:1] setHidden:TRUE];
	}
	
	if ([slideViews.subviews count] != 0) {
		UIViewWithShadow* verticalLineView = [[[UIViewWithShadow alloc] initWithFrame:CGRectMake(-40, 0, 40 , self.view.frame.size.height)] autorelease];
		[verticalLineView setBackgroundColor:[UIColor clearColor]];
		[verticalLineView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
		[verticalLineView setClipsToBounds:NO];
		[controller.view addSubview:verticalLineView];
	}
	
	[viewControllersStack addObject:controller];
	if (invokeByController !=nil) {
		viewXPosition = invokeByController.view.frame.origin.x + invokeByController.view.frame.size.width;			
	}
	if ([[slideViews subviews] count] == 0) {
		slideStartPosition = SLIDE_VIEWS_START_X_POS;
		viewXPosition = slideStartPosition;
	}
	[[controller view] setFrame:CGRectMake(viewXPosition, 0, [controller view].frame.size.width, self.view.frame.size.height)];
	
	[controller.view setTag:([viewControllersStack count]-1)];
	[controller viewWillAppear:FALSE];
	[controller viewDidAppear:FALSE];
	[slideViews addSubview:[controller view]];
	
	
	if ([[slideViews subviews] count] > 0) {
		
		if ([[slideViews subviews] count]==1) {
			viewAtLeft = [[slideViews subviews] objectAtIndex:[[slideViews subviews] count]-1];
			viewAtLeft2 = nil;
			viewAtRight = nil;
			viewAtRight2 = nil;
			
		}else if ([[slideViews subviews] count]==2){
			viewAtRight = [[slideViews subviews] objectAtIndex:[[slideViews subviews] count]-1];
			viewAtLeft = [[slideViews subviews] objectAtIndex:[[slideViews subviews] count]-2];
			viewAtLeft2 = nil;
			viewAtRight2 = nil;
			
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:viewAtLeft cache:YES];	
			[UIView setAnimationBeginsFromCurrentState:NO];	
			[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
			[viewAtRight setFrame:CGRectMake(self.view.frame.size.width - viewAtRight.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
			[UIView commitAnimations];
			slideStartPosition = SLIDE_VIEWS_MINUS_X_POSITION;
			
		}else {
			
			
				viewAtRight = [[slideViews subviews] objectAtIndex:[[slideViews subviews] count]-1];
				viewAtLeft = [[slideViews subviews] objectAtIndex:[[slideViews subviews] count]-2];
				viewAtLeft2 = [[slideViews subviews] objectAtIndex:[[slideViews subviews] count]-3];
				[viewAtLeft2 setHidden:FALSE];
				viewAtRight2 = nil;
				
				[UIView beginAnimations:nil context:NULL];
				[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:viewAtLeft cache:YES];	
				[UIView setAnimationBeginsFromCurrentState:NO];	
				
                if (viewAtLeft2.frame.origin.x != SLIDE_VIEWS_MINUS_X_POSITION) {
                    [viewAtLeft2 setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft2.frame.origin.y, viewAtLeft2.frame.size.width, viewAtLeft2.frame.size.height)];
                }
                [viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
				[viewAtRight setFrame:CGRectMake(self.view.frame.size.width - viewAtRight.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
				[UIView setAnimationDelegate:self];
				[UIView setAnimationDidStopSelector:@selector(bounceBack:finished:context:)];
				[UIView commitAnimations];				
				slideStartPosition = SLIDE_VIEWS_MINUS_X_POSITION;	
				if([[slideViews subviews] count] > 3){
					[[[slideViews subviews] objectAtIndex:[[slideViews subviews] count]-4] setHidden:TRUE];		
				}
			
			
		}
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	for (UIViewController* subController in viewControllersStack) {
		[subController viewDidUnload];
	}
}


#pragma mark -
#pragma mark Rotation support


// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


-(void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	BOOL isViewOutOfScreen = FALSE; 
	for (UIViewController* subController in viewControllersStack) {
		if (viewAtRight != nil && [viewAtRight isEqual:subController.view]) {
			if (viewAtRight.frame.origin.x <= (viewAtLeft.frame.origin.x + viewAtLeft.frame.size.width)) {
				[subController.view setFrame:CGRectMake(self.view.frame.size.width - subController.view.frame.size.width, subController.view.frame.origin.y, subController.view.frame.size.width, self.view.frame.size.height)];
			}else{
				[subController.view setFrame:CGRectMake(viewAtLeft.frame.origin.x + viewAtLeft.frame.size.width, subController.view.frame.origin.y, subController.view.frame.size.width, self.view.frame.size.height)];
			}
			isViewOutOfScreen = TRUE;
		}
		else if (viewAtLeft != nil && [viewAtLeft isEqual:subController.view]) {
			if (viewAtLeft2 == nil) {
				if(viewAtRight == nil){					
					[subController.view setFrame:CGRectMake(SLIDE_VIEWS_START_X_POS, subController.view.frame.origin.y, subController.view.frame.size.width, self.view.frame.size.height)];
				}
				else{
					[subController.view setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, subController.view.frame.origin.y, subController.view.frame.size.width, self.view.frame.size.height)];
					[viewAtRight setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION + subController.view.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
				}
			}
			else if (viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION || viewAtLeft.frame.origin.x == SLIDE_VIEWS_START_X_POS) {
				[subController.view setFrame:CGRectMake(subController.view.frame.origin.x, subController.view.frame.origin.y, subController.view.frame.size.width, self.view.frame.size.height)];
			}
			else {
				if (viewAtLeft.frame.origin.x + viewAtLeft.frame.size.width == self.view.frame.size.width) {
					[subController.view setFrame:CGRectMake(self.view.frame.size.width - subController.view.frame.size.width, subController.view.frame.origin.y, subController.view.frame.size.width, self.view.frame.size.height)];
				}else{
					[subController.view setFrame:CGRectMake(viewAtLeft2.frame.origin.x + viewAtLeft2.frame.size.width, subController.view.frame.origin.y, subController.view.frame.size.width, self.view.frame.size.height)];
				}
			}
		}
		else if(!isViewOutOfScreen){
			[subController.view setFrame:CGRectMake(subController.view.frame.origin.x, subController.view.frame.origin.y, subController.view.frame.size.width, self.view.frame.size.height)];
		}
		else {
			[subController.view setFrame:CGRectMake(self.view.frame.size.width, subController.view.frame.origin.y, subController.view.frame.size.width, self.view.frame.size.height)];
		}
		
	}
	for (UIViewController* subController in viewControllersStack) {
		[subController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration]; 		
		if (!((viewAtRight != nil && [viewAtRight isEqual:subController.view]) || (viewAtLeft != nil && [viewAtLeft isEqual:subController.view]) || (viewAtLeft2 != nil && [viewAtLeft2 isEqual:subController.view]))) {
			[[subController view] setHidden:TRUE];		
		}
		
	}       	
	
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {	
	for (UIViewController* subController in viewControllersStack) {
		[subController didRotateFromInterfaceOrientation:fromInterfaceOrientation];                
	}
	if (viewAtLeft !=nil) {
		[viewAtLeft setHidden:FALSE];
	}
	if (viewAtRight !=nil) {
		[viewAtRight setHidden:FALSE];
	}	
	if (viewAtLeft2 !=nil) {
		[viewAtLeft2 setHidden:FALSE];
	}	
}

- (void)dealloc {
	[slideViews release];
	[viewControllersStack release];
    [super dealloc];
}


@end