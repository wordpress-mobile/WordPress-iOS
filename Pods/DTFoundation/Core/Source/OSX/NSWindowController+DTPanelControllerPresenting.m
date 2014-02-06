//
//  NSWindow+DTViewControllerPresenting.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 10/1/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "objc/runtime.h"
#import "NSWindowController+DTPanelControllerPresenting.h"
#import "DTLog.h"

static char DTPresentedViewControllerKey;
static char DTPresentedViewControllerDismissalQueueKey;

@implementation NSWindowController (DTPanelControllerPresenting)

#pragma mark - Private Methods

// called as a result of the sheed ending
- (void)_didFinishDismissingSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
	NSAssert(contextInfo == &DTPresentedViewControllerDismissalQueueKey, @"Incorrect context info");
	
	// release the panel controller
	objc_setAssociatedObject(self, &DTPresentedViewControllerDismissalQueueKey, nil, OBJC_ASSOCIATION_RETAIN);
}

#pragma mark - Public Methods

- (void)presentModalPanelController:(NSWindowController *)panelController
{
	NSWindowController *windowController = self.modalPanelController;
	
	if (windowController)
	{
		DTLogError(@"Already presenting %@, cannot modally present another panel", NSStringFromClass([windowController class]));
		return;
	}

	// retain the panel view controller
	objc_setAssociatedObject(self, &DTPresentedViewControllerKey, panelController, OBJC_ASSOCIATION_RETAIN);

	// begin the sheet and set our own custom didEndElector which frees the controller
	[NSApp beginSheet:panelController.window modalForWindow:self.window modalDelegate:self didEndSelector:@selector(_didFinishDismissingSheet:returnCode:contextInfo:) contextInfo:&DTPresentedViewControllerDismissalQueueKey];
}

- (void)dismissModalPanelController
{
	NSWindowController *windowController = self.modalPanelController;
	
	if (!windowController)
	{
		DTLogError(@"%s called, but nothing to dismiss", (const char *)__PRETTY_FUNCTION__);
		return;
	}
	
	// retain it in the dismissal queue so that we can present a new one right after the out animation has finished
	objc_setAssociatedObject(self, &DTPresentedViewControllerDismissalQueueKey, windowController, OBJC_ASSOCIATION_RETAIN);
	
	// dismiss the panel
	[windowController.window close];
	[NSApp endSheet:windowController.window];
	
	// free the controller reference
	objc_setAssociatedObject(self, &DTPresentedViewControllerKey, nil, OBJC_ASSOCIATION_RETAIN);
}

- (NSWindowController *)modalPanelController
{
	return objc_getAssociatedObject(self, &DTPresentedViewControllerKey);
}

@end
