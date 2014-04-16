#import "WPTableHeaderViewCell.h"
#import "WPStyleGuide.h"


static CGFloat const WPTableHeaderTextMaxWidth = 200.0f;

@implementation WPTableHeaderViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		self.textLabel.font			= [WPStyleGuide regularTextFont];
		self.textLabel.textColor	= [WPStyleGuide newKidOnTheBlockBlue];
		self.backgroundColor		= [UIColor clearColor];
	}
	
	return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	[super touchesBegan:touches withEvent:event];
	self.backgroundColor = [WPStyleGuide notificationsDarkGrey];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesEnded:touches withEvent:event];
	self.backgroundColor = [WPStyleGuide notificationsLightGrey];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesCancelled:touches withEvent:event];
	self.backgroundColor = [UIColor clearColor];
}

+ (CGFloat)cellHeightForText:(NSString *)text
{
	NSDictionary *attributes	= @{ NSFontAttributeName: [WPStyleGuide tableviewTextFont] };
	CGRect rect					= [text boundingRectWithSize:CGSizeMake(WPTableHeaderTextMaxWidth, MAXFLOAT)
										 options:NSStringDrawingUsesLineFragmentOrigin
									  attributes:attributes
										 context:nil];
	
	return ceil(rect.size.height);
}

@end
