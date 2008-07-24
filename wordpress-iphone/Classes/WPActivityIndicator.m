#import "WPActivityIndicator.h"

@implementation WPActivityIndicator
@synthesize window;
static WPActivityIndicator *activityIndicator;

- (id) init
{
	self = [super init];
	if (self != nil) {
		[[NSBundle mainBundle] loadNibNamed:@"WPActivityIndicator" owner:self options:nil];
	}
	return self;
}

+ (WPActivityIndicator *)sharedActivityIndicator {

	if (!activityIndicator)
	{	
		activityIndicator = [[WPActivityIndicator alloc] init];
		activityIndicator.window.windowLevel = UIWindowLevelAlert;
	}
	
	return activityIndicator;
}

- (void)show {
	[window makeKeyAndVisible];
	window.hidden = NO;
}

- (void)hide {
	[window resignKeyWindow];
	window.hidden = YES;
}

@end
