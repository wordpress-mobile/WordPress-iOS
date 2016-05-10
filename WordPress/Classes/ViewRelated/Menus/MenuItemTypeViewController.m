#import "MenuItemTypeViewController.h"
#import "MenuItemTypeSelectionView.h"
#import "BlogService.h"
#import "Blog.h"
#import "PostType.h"

@interface MenuItemTypeViewController () <MenuItemTypeViewDelegate>

@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, strong, readonly) UIStackView *stackView;
@property (nonatomic, strong, readonly) NSMutableArray *typeViews;

@end

@implementation MenuItemTypeViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.view.translatesAutoresizingMaskIntoConstraints = NO;

    _typeViews = [NSMutableArray arrayWithCapacity:5];
    
    self.view.contentMode = UIViewContentModeRedraw;

    [self setupScrollView];
    [self setupStackView];
}

- (void)setupScrollView
{
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.backgroundColor = [UIColor clearColor];
    scrollView.clipsToBounds = NO;
    scrollView.scrollsToTop = NO;
    [self.view addSubview:scrollView];
    
    [NSLayoutConstraint activateConstraints:@[
                                              [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
                                              [scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
                                              [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
                                              [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
                                              ]];
    _scrollView = scrollView;
}

- (void)setupStackView
{
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.alignment = UIStackViewAlignmentTop;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.axis = UILayoutConstraintAxisVertical;
    
    NSAssert(_scrollView != nil, @"scrollView is nil");
    [_scrollView addSubview:stackView];
    
    [NSLayoutConstraint activateConstraints:@[
                                              [stackView.leadingAnchor constraintEqualToAnchor:_scrollView.leadingAnchor],
                                              [stackView.topAnchor constraintEqualToAnchor:_scrollView.topAnchor],
                                              [stackView.trailingAnchor constraintEqualToAnchor:_scrollView.trailingAnchor],
                                              [stackView.bottomAnchor constraintEqualToAnchor:_scrollView.bottomAnchor]
                                              ]];
    _stackView = stackView;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    [self focusSelectedTypeViewIfNeeded:NO];
}

- (void)setSelectedItemType:(NSString *)selectedItemType
{
    if (_selectedItemType != selectedItemType) {
        _selectedItemType = selectedItemType;
        [self updateSelectedItemTypeView];
    }
}

- (void)loadPostTypesForBlog:(Blog *)blog
{
    // Add default types.
    [self addDefaultItemTypesForBlog:blog];
    [self updateSelectedItemTypeView];
    
    // Sync the available postTypes for blog
    __weak __typeof__(self) weakSelf = self;
    BlogService *service = [[BlogService alloc] initWithManagedObjectContext:blog.managedObjectContext];
    [service syncPostTypesForBlog:blog success:^{
        // synced post types
        [weakSelf addCustomBlogPostTypesIfNeeded:blog];
    } failure:^(NSError *error) {
        DDLogError(@"Error syncing post-types for Menus: %@", error);
    }];
}

- (void)updateDesignForLayoutChangeIfNeeded
{
    for (MenuItemTypeSelectionView *typeView in self.typeViews) {
        [typeView updateDesignForLayoutChangeIfNeeded];
    }
}

- (void)focusSelectedTypeViewIfNeeded:(BOOL)animated
{
    MenuItemTypeSelectionView *selectedTypeView = [self typeViewForItemType:self.selectedItemType];
    CGRect frame = selectedTypeView.frame;
    const CGFloat padding = 4.0;
    frame.origin.y -= padding;
    frame.size.height += padding * 2.0;
    [self.scrollView scrollRectToVisible:frame animated:animated];
}

- (void)addDefaultItemTypesForBlog:(Blog *)blog
{
    MenuItemTypeSelectionView *firstTypeView = [self addTypeView:MenuItemTypePage blog:blog];
    firstTypeView.designIgnoresDrawingTopBorder = YES;
    
    [self addTypeView:MenuItemTypeCustom blog:blog];
    [self addTypeView:MenuItemTypeCategory blog:blog];
    [self addTypeView:MenuItemTypeTag blog:blog];
    [self addTypeView:MenuItemTypePost blog:blog];
}

- (void)addCustomBlogPostTypesIfNeeded:(Blog *)blog
{
    if (!blog.postTypes.count) {
        return;
    }
    NSMutableArray <PostType *> *postTypes = [NSMutableArray arrayWithArray:[blog.postTypes allObjects]];
    [postTypes sortUsingSelector:@selector(label)];
    for (PostType *postType in postTypes) {
        // Not queryable, skip.
        if (!postType.apiQueryable.boolValue) {
            continue;
        }
        // Already have a type for this postType, skip.
        if ([self typeViewForItemType:postType.name]) {
            continue;
        }
        // Add this postType as a typeView.
        [self addTypeView:postType.name blog:blog];
    }
    [self updateSelectedItemTypeView];
}

- (void)updateSelectedItemTypeView
{
    for (MenuItemTypeSelectionView *typeView in self.typeViews) {
        if (typeView.selected) {
            typeView.selected = NO;
        }
    }
    MenuItemTypeSelectionView *selectedView = [self typeViewForItemType:self.selectedItemType];
    selectedView.selected = YES;
}

- (MenuItemTypeSelectionView *)addTypeView:(NSString *)itemType blog:(Blog *)blog
{
    MenuItemTypeSelectionView *typeView = [[MenuItemTypeSelectionView alloc] init];
    typeView.delegate = self;
    typeView.itemType = itemType;
    typeView.itemTypeLabel = [MenuItem labelForType:itemType blog:blog];
    [self.stackView addArrangedSubview:typeView];
    [typeView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor].active = YES;
    [self.typeViews addObject:typeView];
    return typeView;
}

- (MenuItemTypeSelectionView *)typeViewForItemType:(NSString *)itemType
{
    MenuItemTypeSelectionView *itemTypeView = nil;
    for (MenuItemTypeSelectionView *typeView in self.typeViews) {
        if ([typeView.itemType isEqualToString:itemType]) {
            itemTypeView = typeView;
            break;
        }
    }
    return itemTypeView;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 2.0);
    CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten30] CGColor]);
    CGContextMoveToPoint(context, rect.size.width, 0);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

#pragma mark - delegate

- (void)tellDelegateTypeChanged:(NSString *)itemType
{
    [self.delegate itemTypeViewController:self selectedType:itemType];
}

#pragma mark - MenuItemTypeViewDelegate

- (void)typeViewPressedForSelection:(MenuItemTypeSelectionView *)typeView
{
    self.selectedItemType = typeView.itemType;
    [self focusSelectedTypeViewIfNeeded:YES];
    [self tellDelegateTypeChanged:typeView.itemType];
}

- (BOOL)typeViewRequiresCompactLayout:(MenuItemTypeSelectionView *)typeView
{
    return ![self.delegate itemTypeViewControllerShouldDisplayFullSizedLayout:self];
}

@end
