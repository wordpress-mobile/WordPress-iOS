/*
 * Copyright 2012 Quantcast Corp.
 *
 * This software is licensed under the Quantcast Mobile App Measurement Terms of Service
 * https://www.quantcast.com/learning-center/quantcast-terms/mobile-app-measurement-tos
 * (the “License”). You may not use this file unless (1) you sign up for an account at
 * https://www.quantcast.com and click your agreement to the License and (2) are in
 * compliance with the License. See the License for the specific language governing
 * permissions and limitations under the License.
 *
 */

#import <Foundation/Foundation.h>

/*!
 @protocol QuantcastOptOutDelegate
 @abstract A delegate protocol that provides various notifications from Quantcast's User Privacy dialog.
 @discussion A delegate to the Quantcast user privacy dialog should adopt this protocol. All methods in this protocol are optional.
 */
@protocol QuantcastOptOutDelegate <NSObject>

@optional

/*!
 @method quantcastOptOutStatusDidChange:
 @abstract Delegate method called when user has changed their opt-out status
 @param inOptOutStatus A BOOL indicating the new value of the user's opt-out status.
 */
-(void)quantcastOptOutStatusDidChange:(BOOL)inOptOutStatus;

/*!
 @method quantcastOptOutDialogWillAppear
 @abstract Notifies the delegate that the Quantcast opt-out dialog is about to appear
 */
-(void)quantcastOptOutDialogWillAppear;

/*!
 @method quantcastOptOutDialogDidAppear
 @abstract Notifies the delegate that the Quantcast opt-out dialog has appeared.
 */
-(void)quantcastOptOutDialogDidAppear;

/*!
 @method quantcastOptOutDialogWillDisappear
 @abstract Notifies the delegate that the Quantcast opt-out dialog is about to be removed from view.
 */
-(void)quantcastOptOutDialogWillDisappear;

/*!
 @method quantcastOptOutDialogDidDisappear
 @abstract Notifies the delegate that the Quantcast opt-out dialog has been removed from view.
 */
-(void)quantcastOptOutDialogDidDisappear;

@end
