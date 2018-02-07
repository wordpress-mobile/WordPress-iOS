#import "WPTableViewCell.h"
#import "WPDeviceIdentification.h"

CGFloat const WPTableViewFixedWidth = 600;

@implementation WPTableViewCell

- (void)setForceCustomCellMargins:(BOOL)forceCustomCellMargins
{
	if (_forceCustomCellMargins != forceCustomCellMargins) {
		_forceCustomCellMargins = forceCustomCellMargins;
		[self setClipsToBounds:forceCustomCellMargins];
	}
}

- (void)setFrame:(CGRect)frame {
	if (self.forceCustomCellMargins) {
		CGFloat width = self.superview.frame.size.width;
		// On iPad, add a margin around tables
		if ([WPDeviceIdentification isiPad] && width > WPTableViewFixedWidth) {
			CGFloat x = (width - WPTableViewFixedWidth) / 2;
			// If origin.x is not equal to x we add the value.
			// This is a semi-fix / work around for an issue positioning cells on
			// iOS 8 when editing a table view and the delete button is visible.
			if (x != frame.origin.x) {
				frame.origin.x += x;
			} else {
				frame.origin.x = x;
			}
			frame.size.width = WPTableViewFixedWidth;
		}
	}
	[super setFrame:frame];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	if (self.forceCustomCellMargins) {
		// Need to set the origin again on iPad (for margins)
		CGFloat width = self.superview.frame.size.width;
		if ([WPDeviceIdentification isiPad] && width > WPTableViewFixedWidth) {
			CGRect frame = self.frame;
			frame.origin.x = (width - WPTableViewFixedWidth) / 2;
			self.frame = frame;
		}
	}
}

@end
