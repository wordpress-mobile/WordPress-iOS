#import "MenuItemSourceContainerView.h"
#import "MenusDesign.h"
#import "MenuItemSourceHeaderView.h"
#import "MenuItemSourcePageView.h"
#import "MenuItemSourceLinkView.h"
#import "MenuItemSourceCategoryView.h"
#import "MenuItemSourceTagView.h"
#import "MenuItemSourcePostView.h"
#import "Menu.h"

@interface MenuItemSourceContainerView () <MenuItemSourceHeaderViewDelegate, MenuItemSourceViewDelegate>

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) MenuItemSourceHeaderView *headerView;
@property (nonatomic, strong) MenuItemSourceView *sourceView;
@property (nonatomic, strong) NSCache *sourceViewCache;

@end

@implementation MenuItemSourceContainerView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor whiteColor];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.sourceViewCache = [[NSCache alloc] init];
    
    {
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.spacing = 0;
        [self addSubview:stackView];
        
        [NSLayoutConstraint activateConstraints:@[
                                                  [stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                                  [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                                  [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                                                  [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
                                                  [stackView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor]
                                                  ]];
        
        self.stackView = stackView;
    }
    {
        MenuItemSourceHeaderView *headerView = [[MenuItemSourceHeaderView alloc] init];
        headerView.delegate = self;
        [self.stackView addArrangedSubview:headerView];
        
        NSLayoutConstraint *height = [headerView.heightAnchor constraintEqualToConstant:60.0];
        height.priority = 999;
        height.active = YES;
        
        [headerView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        [headerView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        
        self.headerView = headerView;
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if(self.frame.size.width > self.frame.size.height) {
        [self setHeaderViewHidden:YES];
    }else {
        [self setHeaderViewHidden:NO];
    }
}

- (Blog *)blog
{
    return self.item.menu.blog;
}

- (void)setHeaderViewHidden:(BOOL)hidden
{
    if(self.headerView.hidden != hidden) {
        self.headerView.hidden = hidden;
        self.headerView.alpha = hidden ? 0.0 : 1.0;
    }
}

- (void)setItem:(MenuItem *)item
{
    if(_item != item) {
        _item = item;
        [self updateSourceSelectionForItem];
    }
}

- (void)updateSourceSelectionForItem
{
    NSString *itemType = self.item.type;
    self.headerView.titleLabel.text = [MenuItem labelForType:itemType blog:[self blog]];
    [self showSourceViewForItemType:itemType];
}

- (void)showSourceViewForItemType:(NSString *)itemType
{
    if(self.sourceView) {
        [self.stackView removeArrangedSubview:self.sourceView];
        [self.sourceView removeFromSuperview];
        self.sourceView = nil;
    }
    
    MenuItemSourceView *sourceView = [self.sourceViewCache objectForKey:itemType];
    BOOL shouldSetItem = NO;
    if(!sourceView) {
        if ([itemType isEqualToString:MenuItemTypePage]) {
            sourceView = [[MenuItemSourcePageView alloc] init];
        } else if([itemType isEqualToString:MenuItemTypeCustom]) {
            sourceView = [[MenuItemSourceLinkView alloc] init];
        } else if([itemType isEqualToString:MenuItemTypeCategory]) {
            sourceView = [[MenuItemSourceCategoryView alloc] init];
        } else if([itemType isEqualToString:MenuItemTypeTag]) {
            sourceView = [[MenuItemSourceTagView alloc] init];
        } else if([itemType isEqualToString:MenuItemTypePost]) {
            sourceView = [[MenuItemSourcePostView alloc] init];
        }
        sourceView.delegate = self;
        shouldSetItem = YES;
    }
    
    if(sourceView) {
        [sourceView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        [self.stackView addArrangedSubview:sourceView];
        self.sourceView = sourceView;
        if (shouldSetItem) {
            sourceView.item = self.item;
        }
        [self.sourceViewCache setObject:sourceView forKey:itemType];
    }
}

#pragma mark - MenuItemSourceHeaderViewDelegate

- (void)sourceHeaderViewSelected:(MenuItemSourceHeaderView *)headerView
{
    [self.sourceView resignFirstResponder];
    [self.delegate sourceContainerViewSelectedTypeHeaderView:self];
}

#pragma mark - MenuItemSourceViewDelegate

- (void)sourceViewDidBeginEditingWithKeyBoard:(MenuItemSourceView *)sourceView
{
    [self.delegate sourceContainerViewDidBeginEditingWithKeyboard:self];
}

- (void)sourceViewDidEndEditingWithKeyboard:(MenuItemSourceView *)sourceView
{
    [self.delegate sourceContainerViewDidEndEditingWithKeyboard:self];
}

@end
