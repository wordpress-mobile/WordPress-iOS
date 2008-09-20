#import "WPNavigationLeftButtonView.h"


@implementation WPNavigationLeftButtonView

@dynamic title;

+ (WPNavigationLeftButtonView *) createView  {
	
	UIApplication *app = [UIApplication sharedApplication];
	UIInterfaceOrientation statusOrientation = [app statusBarOrientation];
	if(statusOrientation == UIInterfaceOrientationLandscapeLeft || statusOrientation == UIInterfaceOrientationLandscapeRight)
	{
		
		WPLog(@" UIInterfaceOrientationIsLandscape ");
		return [[WPNavigationLeftButtonView alloc] initWithFrame:CGRectMake(0, 0, 60, 25)];
	}  
    WPLog(@" UIInterfaceOrientationPotrait ");
	return [[WPNavigationLeftButtonView alloc] initWithFrame:CGRectMake(0, 0, 65, 30)];
}


- (NSString *)title {
    return addLabel.text;
}

- (void)setTitle:(NSString*)aTitle {
    addLabel.text = aTitle;
}


-(void)setTarget:(id)aTarget withAction:(SEL)action{
    [addButton addTarget:aTarget action:action forControlEvents:UIControlEventTouchUpInside];
}



- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
        CGRect rect = frame;
        addButton = [[UIButton alloc] initWithFrame:rect];
        UIImage *img = [UIImage imageNamed:@"backNav.png"];
        [addButton setImage:img forState:UIControlStateNormal];
        [addButton setImage:img forState:UIControlStateHighlighted];
        [addButton setImage:img forState:UIControlStateSelected];
        
        rect.origin.y +=3;
        rect.size.height -=10;
        
        addLabel = [[UILabel alloc] initWithFrame:rect];
        addLabel.backgroundColor = [UIColor clearColor];
        addLabel.lineBreakMode = UILineBreakModeTailTruncation;
        addLabel.textColor = [UIColor whiteColor];
        addLabel.font = [UIFont boldSystemFontOfSize:13];
        [addLabel setTextAlignment:UITextAlignmentCenter];
		
        [self addSubview:addButton];
        [self addSubview:addLabel];
        
    }
    return self;
}

- (void)dealloc {
    
	
    [addButton release];
    [addLabel release];
    [super dealloc];
}


@end
