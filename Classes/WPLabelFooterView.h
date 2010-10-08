//
//  WPLabelFooterView.h
//  WordPress
//
//  Created by JanakiRam on 02/02/09.

#import <UIKit/UIKit.h>

@interface WPLabelFooterView : UIView {
@private
    UILabel *label;
}

@property (nonatomic, retain) UILabel *label;

- (void)setText:(NSString *)labelText;
- (NSString *)text;
- (void)setTextAlignment:(UITextAlignment)labelTextAlignment;
- (UITextAlignment)textAlignment;
- (void)setNumberOfLines:(NSInteger)numberOfLines;
- (NSInteger)numberOfLines;

@end
