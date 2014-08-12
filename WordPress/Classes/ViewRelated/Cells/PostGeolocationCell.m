#import "PostGeolocationCell.h"
#import <MapKit/MapKit.h>

#import "PostGeolocationView.h"

CGFloat const PostGeolocationCellMargin = 15.0f;

@interface PostGeolocationCell ()

@property (nonatomic, strong) PostGeolocationView *geoView;

@end

@implementation PostGeolocationCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self configureSubviews];
    }
    return self;
}

- (void)configureSubviews
{
    self.geoView = [[PostGeolocationView alloc] initWithFrame:self.contentView.bounds];
    self.geoView.labelMargin = 0.0f;
    self.geoView.scrollEnabled = NO;
    self.geoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentView addSubview:self.geoView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat x = PostGeolocationCellMargin;
    CGFloat y = PostGeolocationCellMargin;
    CGFloat w = CGRectGetWidth(self.contentView.frame) - (PostGeolocationCellMargin * 2);
    CGFloat h = CGRectGetHeight(self.contentView.frame) - (PostGeolocationCellMargin * 2);

    self.geoView.frame = CGRectMake(x, y, w, h);
}

- (void)setCoordinate:(Coordinate *)coordinate andAddress:(NSString *)address
{
    self.geoView.coordinate = coordinate;
    self.geoView.address = address;
}

@end
