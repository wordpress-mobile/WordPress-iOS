//
//  DTAlertView.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 11/22/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

// the block to execute when an alert button is tapped
typedef void (^DTAlertViewBlock)(void);

/**
 Extends UIAlertView with support for blocks
 */

@interface DTAlertView : UIAlertView

/**
* Initializes the alert view. Add buttons and their blocks afterwards.
 @param title The alert title
 @param message The alert message
*/
- (id)initWithTitle:(NSString *)title message:(NSString *)message;

/**
 Adds a button to the alert view

 @param title The title of the new button.
 @param block The block to execute when the button is tapped.
 @returns The index of the new button. Button indices start at 0 and increase in the order they are added.
 */
- (NSInteger)addButtonWithTitle:(NSString *)title block:(DTAlertViewBlock)block;

/**
 Same as above, but for a cancel button.
 @param title The title of the cancel button.
 @param block The block to execute when the button is tapped.
 @returns The index of the new button. Button indices start at 0 and increase in the order they are added.
 */
- (NSInteger)addCancelButtonWithTitle:(NSString *)title block:(DTAlertViewBlock)block;

/**
 Set a block to be run on alertViewCancel:.
 @param block The block to execute.
 */
- (void)setCancelBlock:(DTAlertViewBlock)block;

@end
