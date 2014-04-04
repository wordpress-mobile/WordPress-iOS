#import "ReaderTableViewCell.h"
#import "WPWebViewController.h"

@implementation ReaderTableViewCell

#pragma mark - Lifecycle Methods

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {

		self.cellImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 44.0f, 44.0f)]; // arbitrary size.
		_cellImageView.backgroundColor = [WPStyleGuide readGrey];
		_cellImageView.contentMode = UIViewContentModeScaleAspectFill;
		_cellImageView.clipsToBounds = YES;
		[self.contentView addSubview:_cellImageView];
    }
	
    return self;
}


- (void)prepareForReuse {
	[super prepareForReuse];
	[_cellImageView cancelImageRequestOperation];
	_cellImageView.image = nil;
}


@end
