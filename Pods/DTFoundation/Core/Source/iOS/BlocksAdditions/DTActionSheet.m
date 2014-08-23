//
//  DTActionSheet.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 08.06.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTActionSheet.h"
#import "DTWeakSupport.h"

@interface DTActionSheet () <UIActionSheetDelegate>

@end

@implementation DTActionSheet
{
	DT_WEAK_VARIABLE id <UIActionSheetDelegate> _externalDelegate;
	
	NSMutableDictionary *_actionsPerIndex;
	
	// lookup bitmask what delegate methods are implemented
	struct 
	{
		unsigned int delegateSupportsActionSheetCancel:1;
		unsigned int delegateSupportsWillPresentActionSheet:1;
		unsigned int delegateSupportsDidPresentActionSheet:1;
		unsigned int delegateSupportsWillDismissWithButtonIndex:1;
		unsigned int delegateSupportsDidDismissWithButtonIndex:1;
		unsigned int delegateSupportsClickedButtonAtIndex:1;
	} _delegateFlags;
	
	BOOL _isDeallocating;
}

// designated initializer
- (id)init
{
    self = [super init];
    if (self)
    {
        _actionsPerIndex = [[NSMutableDictionary alloc] init];
        self.delegate = self;
        
    }
    return self;
}

- (id)initWithTitle:(NSString *)title
{
    return [self initWithTitle:title delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
}

- (id)initWithTitle:(NSString *)title delegate:(id<UIActionSheetDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...
{
	self = [self init];
	if (self) 
	{
        self.title = title;
        
        if (otherButtonTitles != nil) {
            [self addButtonWithTitle:otherButtonTitles];
            va_list args;
            va_start(args, otherButtonTitles);
            NSString *title = nil;
            while( (title = va_arg(args, NSString *)) ) {
                [self addButtonWithTitle:title];
            }
            va_end(args);
        }
        
        if (destructiveButtonTitle) {
            [self addDestructiveButtonWithTitle:destructiveButtonTitle block:nil];
        }
        if (cancelButtonTitle) {
            [self addCancelButtonWithTitle:cancelButtonTitle block:nil];
        }

        _externalDelegate = delegate;
	}
	
	return self;
}

- (void)dealloc
{
	_isDeallocating = YES;
}

- (NSInteger)addButtonWithTitle:(NSString *)title block:(DTActionSheetBlock)block
{
	NSInteger retIndex = [self addButtonWithTitle:title];
	
	if (block)
	{
		NSNumber *key = [NSNumber numberWithInteger:retIndex];
		[_actionsPerIndex setObject:[block copy] forKey:key];
	}
	
	return retIndex;
}

- (NSInteger)addDestructiveButtonWithTitle:(NSString *)title block:(DTActionSheetBlock)block
{
	NSInteger retIndex = [self addButtonWithTitle:title block:block];
	[self setDestructiveButtonIndex:retIndex];
	
	return retIndex;
}

- (NSInteger)addCancelButtonWithTitle:(NSString *)title
{
    return [self addCancelButtonWithTitle:title block:nil];
}

- (NSInteger)addCancelButtonWithTitle:(NSString *)title block:(DTActionSheetBlock)block
{
	NSInteger retIndex = [self addButtonWithTitle:title block:block];
	[self setCancelButtonIndex:retIndex];
	
	return retIndex;
}

#pragma mark - UIActionSheetDelegate (forwarded)

- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
	if (_delegateFlags.delegateSupportsActionSheetCancel)
	{
		[_externalDelegate actionSheetCancel:actionSheet];
	}
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet
{
	if (_delegateFlags.delegateSupportsWillPresentActionSheet)
	{
		[_externalDelegate willPresentActionSheet:actionSheet];	
	}
}

- (void)didPresentActionSheet:(UIActionSheet *)actionSheet
{
	if (_delegateFlags.delegateSupportsDidPresentActionSheet)
	{
		[_externalDelegate didPresentActionSheet:actionSheet];
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (_delegateFlags.delegateSupportsWillDismissWithButtonIndex)
	{
		[_externalDelegate actionSheet:actionSheet willDismissWithButtonIndex:buttonIndex];
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (_delegateFlags.delegateSupportsDidDismissWithButtonIndex)
	{
		[_externalDelegate actionSheet:actionSheet didDismissWithButtonIndex:buttonIndex];
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSNumber *key = [NSNumber numberWithInteger:buttonIndex];
	
	DTActionSheetBlock block = [_actionsPerIndex objectForKey:key];
	
	if (block)
	{
		block();
	}

	if (_delegateFlags.delegateSupportsClickedButtonAtIndex)
	{
		[_externalDelegate actionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
	}
}

#pragma mark - Properties

- (id <UIActionSheetDelegate>)delegate
{
	return _externalDelegate;
}

- (void)setDelegate:(id <UIActionSheetDelegate>)delegate
{
	if (delegate == self)
	{
		[super setDelegate:self];
	}
	else if (delegate == nil)
	{
		// UIActionSheet dealloc sets delegate to nil
		if (_isDeallocating)
		{
			[super setDelegate:nil];
		}
		else
		{
			[super setDelegate:self];
		}
		_externalDelegate = nil;
	}
	else 
	{
		_externalDelegate = delegate;
	}
	
	// wipe
	memset(&_delegateFlags, 0, sizeof(_delegateFlags));
	
	// set flags according to available methods in delegate
	if ([_externalDelegate respondsToSelector:@selector(actionSheetCancel:)])
	{
		_delegateFlags.delegateSupportsActionSheetCancel = YES;
	}

	if ([_externalDelegate respondsToSelector:@selector(willPresentActionSheet:)])
	{
		_delegateFlags.delegateSupportsWillPresentActionSheet = YES;
	}

	if ([_externalDelegate respondsToSelector:@selector(didPresentActionSheet:)])
	{
		_delegateFlags.delegateSupportsDidPresentActionSheet = YES;
	}

	if ([_externalDelegate respondsToSelector:@selector(actionSheet:willDismissWithButtonIndex:)])
	{
		_delegateFlags.delegateSupportsWillDismissWithButtonIndex = YES;
	}

	if ([_externalDelegate respondsToSelector:@selector(actionSheet:didDismissWithButtonIndex:)])
	{
		_delegateFlags.delegateSupportsDidDismissWithButtonIndex = YES;
	}
	
	if ([_externalDelegate respondsToSelector:@selector(actionSheet:clickedButtonAtIndex:)])
	{
		_delegateFlags.delegateSupportsClickedButtonAtIndex = YES;
	}
}

@end
