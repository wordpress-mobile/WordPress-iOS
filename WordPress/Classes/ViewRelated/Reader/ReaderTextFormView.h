#import <UIKit/UIKit.h>

#define ReaderTextFormFontSize 14.0f
#define ReaderTextFormMaxLines 8
#define ReaderTextFormMinLines 4

@protocol ReaderTextFormDelegate;

@class IOS7CorrectedTextView;

@interface ReaderTextFormView : UIView <UITextViewDelegate>

@property (nonatomic, weak) id<ReaderTextFormDelegate> delegate;
@property (nonatomic, strong) IOS7CorrectedTextView *textView;
@property (nonatomic, strong) UILabel *promptLabel;
@property (nonatomic, strong) UIImageView *borderImageView;
@property (nonatomic, strong) UINavigationItem *navigationItem;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@property (nonatomic, strong) UIBarButtonItem *sendButton;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic) BOOL requireText;

- (NSString *)text;
- (void)setText:(NSString *)text;
- (void)dismiss;
- (void)handleSendButtonTapped:(id)sender;
- (void)handleCancelButtonTapped:(id)sender;
- (void)updateNavItem;
- (void)configureNavItem;
- (void)enableForm:(BOOL)enabled;
- (BOOL)shouldEnableSendButton;

@end


@protocol ReaderTextFormDelegate <NSObject>

@optional
- (void)readerTextFormWillSend:(ReaderTextFormView *)readerTextForm;
- (void)readerTextFormDidSend:(ReaderTextFormView *)readerTextForm;
- (void)readerTextFormDidCancel:(ReaderTextFormView *)readerTextForm;
- (void)readerTextFormShouldDismiss:(ReaderTextFormView *)readerTextForm;
- (void)readerTextFormDidBeginEditing:(ReaderTextFormView *)readerTextForm;
- (void)readerTextFormDidChange:(ReaderTextFormView *)readerTextForm;
- (void)readerTextFormDidEndEditing:(ReaderTextFormView *)readerTextForm;

@end