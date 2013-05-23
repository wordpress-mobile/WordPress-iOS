//
//  QuickPhotoButtonView.h
//  WordPress
//
//  Created by Eric Johnson on 6/19/12.
//

#import <UIKit/UIKit.h>

@protocol QuickPhotoButtonViewDelegate;

@interface QuickPhotoButtonView : UIView

@property (nonatomic, strong) id<QuickPhotoButtonViewDelegate>delegate;

- (void)showSuccess;
- (void)showProgress:(BOOL)show animated:(BOOL)animated;
- (void)updateProgress:(float)progress;

@end

@protocol QuickPhotoButtonViewDelegate <NSObject>
- (void)quickPhotoButtonTapped:(QuickPhotoButtonView *)sender;
- (void)quickPhotoProgressButtonTapped:(QuickPhotoButtonView *)sender;
@end