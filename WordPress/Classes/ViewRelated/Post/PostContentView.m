#import "PostContentView.h"
#import "Post.h"
#import "ContentActionButton.h"
#import "PostAttributionView.h"
#import "PostContentActionView.h"

@interface PostContentView ()

@property (nonatomic, strong) Post *post;
@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, strong) UIButton *deleteButton;

@end

@implementation PostContentView

#pragma mark - LifeCycle Methods

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Action buttons
        _editButton = [super createActionButtonWithImage:[UIImage imageNamed:@"posts-postaction-edit-blue"] selectedImage:[UIImage imageNamed:@"posts-postaction-edit-blue"]];
        [_editButton addTarget:self action:@selector(editAction:) forControlEvents:UIControlEventTouchUpInside];

        _deleteButton = [super createActionButtonWithImage:[UIImage imageNamed:@"posts-postaction-trash-blue"] selectedImage:[UIImage imageNamed:@"posts-postaction-trash-active"]];
        [_deleteButton addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];

        [super setActionButtons:@[_deleteButton, _editButton]];
    }
    return self;
}

#pragma mark - Public Methods

- (void)configurePost:(Post *)post
{
    self.post = post;
    self.contentProvider = post;
}

#pragma mark - Private Methods

- (WPContentActionView *)viewForActionView
{
    PostContentActionView *actionView = [[PostContentActionView alloc] init];
    actionView.translatesAutoresizingMaskIntoConstraints = NO;
    return actionView;
}

- (WPContentAttributionView *)viewForAttributionView
{
    PostAttributionView *attrView = [[PostAttributionView alloc] init];
    attrView.translatesAutoresizingMaskIntoConstraints = NO;
    [attrView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    return attrView;
}

#pragma mark - Action Methods

- (void)editAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(postView:didReceiveEditAction:)]) {
        [self.delegate postView:self didReceiveEditAction:sender];
    }
}

- (void)deleteAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(postView:didReceiveDeleteAction:)]) {
        [self.delegate postView:self didReceiveDeleteAction:sender];
    }
}

@end
