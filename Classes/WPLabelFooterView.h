//
//  WPLabelFooterView.h
//  WordPress
//
//
//  Created by JanakiRam on 02/02/09.

/*!
    @class	   WPLabelFooterView
    @abstract    This class is used to create the view which contains a label.
    @discussion  This class is used to create the view which contains a label which is used as footer view for tableview.
*/


#import <UIKit/UIKit.h>


@interface WPLabelFooterView : UIView 
{
	@private
	UILabel *label;
}

@property(nonatomic, retain) UILabel *label;

/*!
    @method     setText
    @abstract   sets the label text.
    @discussion sets the label text.
*/
-(void)setText:(NSString *)labelText;

/*!
 @method     text
 @abstract   returns the label text.
 @discussion returns the label text.
 */
-(NSString *)text;

/*!
 @method     setTextAlignment
 @abstract   sets the label textalignment.
 @discussion sets the label textalignment.
 */
-(void)setTextAlignment:(UITextAlignment)labelTextAlignment;

/*!
 @method     textAlignment
 @abstract   returns the label textAlignment.
 @discussion returns the label textAlignment.
 */
-(UITextAlignment)textAlignment;

/*!
 @method     setNumberOfLines
 @abstract   sets the number of lines to be shown in the label.
 @discussion sets the number of lines to be shown in the label.
 */
-(void)setNumberOfLines:(NSInteger)numberOfLines;

/*!
 @method     numberOfLines
 @abstract   returns the number of lines shown in the label.
 @discussion returns the number of lines shown in the label.
 */
-(NSInteger)numberOfLines;

@end
