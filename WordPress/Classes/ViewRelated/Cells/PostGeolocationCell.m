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
    PostGeolocationView *geoView = [[PostGeolocationView alloc] initWithFrame:self.contentView.bounds];
    geoView.translatesAutoresizingMaskIntoConstraints = NO;
    geoView.labelMargin = 0.0f;
    geoView.scrollEnabled = NO;
    geoView.chevronHidden = YES;
    [self.contentView addSubview:geoView];

    UILayoutGuide *readableGuide = self.contentView.readableContentGuide;
    [NSLayoutConstraint activateConstraints:@[
                                              [geoView.leadingAnchor constraintEqualToAnchor:readableGuide.leadingAnchor],
                                              [geoView.trailingAnchor constraintEqualToAnchor:readableGuide.trailingAnchor],
                                              [geoView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:PostGeolocationCellMargin],
                                              [geoView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
                                              ]];
    _geoView = geoView;
}

- (void)setCoordinate:(Coordinate *)coordinate andAddress:(NSString *)address
{
    self.geoView.coordinate = coordinate;
    self.geoView.address = address;
}

@end
