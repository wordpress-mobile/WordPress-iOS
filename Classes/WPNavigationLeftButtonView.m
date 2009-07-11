#import "WPNavigationLeftButtonView.h"

@implementation WPNavigationLeftButtonView

@dynamic title;

+ (WPNavigationLeftButtonView *)createCopyOfView  {
    return [[WPNavigationLeftButtonView alloc] initWithFrame:CGRectMake(0, 0, 65, 31)];
}

- (NSString *)title {
    return addButton.currentTitle;
}

- (void)setTitle:(NSString *)aTitle {
    [addButton setTitle:aTitle forState:UIControlStateNormal];
    [addButton setTitle:aTitle forState:UIControlStateHighlighted];
    [addButton setTitle:aTitle forState:UIControlStateSelected];
}

- (void)setTarget:(id)aTarget withAction:(SEL)action {
    [addButton addTarget:aTarget action:action forControlEvents:UIControlEventTouchUpInside];
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
        CGRect rect = frame;
        addButton = [[UIButton alloc] initWithFrame:rect];
        UIImage *img = [UIImage imageNamed:@"backNav.png"];
        UIImage *imgselect = [UIImage imageNamed:@"backNavd.png"];
        [addButton setBackgroundImage:img forState:UIControlStateNormal];
        [addButton setBackgroundImage:imgselect forState:UIControlStateHighlighted];
        [addButton setBackgroundImage:imgselect forState:UIControlStateSelected];
#if defined __IPHONE_3_0
        addButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
#else if defined __IPHONE_2_0
        [addButton setFont:[UIFont boldSystemFontOfSize:12]];
#endif

        [self addSubview:addButton];
    }

    return self;
}

- (void)dealloc {
    [addButton release];
    [super dealloc];
}

@end
