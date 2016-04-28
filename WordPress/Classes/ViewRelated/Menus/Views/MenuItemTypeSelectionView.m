#import "MenuItemTypeSelectionView.h"
#import "MenuItemTypeView.h"
#import "BlogService.h"
#import "Blog.h"
#import "PostType.h"

@interface MenuItemTypeSelectionView () <MenuItemTypeViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) NSMutableArray *typeViews;

@end

@implementation MenuItemTypeSelectionView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.typeViews = [NSMutableArray arrayWithCapacity:5];
    
    self.backgroundColor = [UIColor whiteColor];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentMode = UIViewContentModeRedraw;

    [self initScrollView];
    [self initStackView];
}

- (void)initScrollView
{
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.backgroundColor = [UIColor clearColor];
    scrollView.clipsToBounds = NO;
    scrollView.scrollsToTop = NO;
    [self addSubview:scrollView];
    
    [NSLayoutConstraint activateConstraints:@[
                                              [scrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                              [scrollView.topAnchor constraintEqualToAnchor:self.topAnchor],
                                              [scrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                                              [scrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
                                              ]];
    self.scrollView = scrollView;
}

- (void)initStackView
{
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.alignment = UIStackViewAlignmentTop;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.axis = UILayoutConstraintAxisVertical;
    [self.scrollView addSubview:stackView];
    
    [NSLayoutConstraint activateConstraints:@[
                                              [stackView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
                                              [stackView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
                                              [stackView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
                                              [stackView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor]
                                              ]];
    self.stackView = stackView;
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
    for (MenuItemTypeView *typeView in self.typeViews) {
        [typeView updateDesignForLayoutChangeIfNeeded];
    }
}

- (void)focusSelectedTypeViewIfNeeded:(BOOL)animated
{
    MenuItemTypeView *selectedTypeView = [self typeViewForItemType:self.selectedItemType];
    CGRect frame = selectedTypeView.frame;
    const CGFloat padding = 4.0;
    frame.origin.y -= padding;
    frame.size.height += padding * 2.0;
    [self.scrollView scrollRectToVisible:frame animated:animated];
}

- (void)addDefaultItemTypesForBlog:(Blog *)blog
{
    MenuItemTypeView *firstTypeView = [self addTypeView:MenuItemTypePage blog:blog];
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
    for (MenuItemTypeView *typeView in self.typeViews) {
        if (typeView.selected) {
            typeView.selected = NO;
        }
    }
    MenuItemTypeView *selectedView = [self typeViewForItemType:self.selectedItemType];
    selectedView.selected = YES;
}

- (MenuItemTypeView *)addTypeView:(NSString *)itemType blog:(Blog *)blog
{
    MenuItemTypeView *typeView = [[MenuItemTypeView alloc] init];
    typeView.delegate = self;
    typeView.itemType = itemType;
    typeView.itemTypeLabel = [MenuItem labelForType:itemType blog:blog];
    [self.stackView addArrangedSubview:typeView];
    [typeView.widthAnchor constraintEqualToAnchor:self.widthAnchor].active = YES;
    [self.typeViews addObject:typeView];
    return typeView;
}

- (MenuItemTypeView *)typeViewForItemType:(NSString *)itemType
{
    MenuItemTypeView *itemTypeView = nil;
    for (MenuItemTypeView *typeView in self.typeViews) {
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
    [self.delegate itemTypeSelectionViewChanged:self type:itemType];
}

#pragma mark - MenuItemTypeViewDelegate

- (void)typeViewPressedForSelection:(MenuItemTypeView *)typeView
{
    self.selectedItemType = typeView.itemType;
    [self focusSelectedTypeViewIfNeeded:YES];
    [self tellDelegateTypeChanged:typeView.itemType];
}

- (BOOL)typeViewRequiresCompactLayout:(MenuItemTypeView *)typeView
{
    return ![self.delegate itemTypeSelectionViewRequiresFullSizedLayout:self];
}

@end
