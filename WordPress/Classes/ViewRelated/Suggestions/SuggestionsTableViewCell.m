#import "SuggestionsTableViewCell.h"
#import <WordPressShared/WPFontManager.h>
#import "WordPress-Swift.h"

NSInteger const SuggestionsTableViewCellIconSize = 24;

@implementation SuggestionsTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupTitleLabel];
        [self setupSubtitleLabel];
        [self setupIconImageView];
        [self setupConstraints];
        self.backgroundColor = [UIColor murielListForeground];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.imageDownloadHash = 0;
}

- (void)setupTitleLabel
{
    _titleLabel = [[UILabel alloc] init];
    [_titleLabel setTextColor:[UIColor murielPrimary]];
    [_titleLabel setFont:[WPFontManager systemRegularFontOfSize:17.0]];
    [_titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.contentView addSubview:_titleLabel];
}

- (void)setupSubtitleLabel
{
    _subtitleLabel = [[UILabel alloc] init];
    [_subtitleLabel setTextColor:[UIColor murielTextSubtle]];
    [_subtitleLabel setFont:[WPFontManager systemRegularFontOfSize:14.0]];
    [_subtitleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    _subtitleLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:_subtitleLabel];
}

- (void)setupIconImageView
{
    _iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SuggestionsTableViewCellIconSize, SuggestionsTableViewCellIconSize)];
    _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    _iconImageView.clipsToBounds = YES;
    [_iconImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.contentView addSubview:_iconImageView];
}

- (void)setupConstraints
{
    NSDictionary *views = @{@"contentview": self.contentView,
                            @"title": _titleLabel,
                            @"subtitle": _subtitleLabel,
                            @"icon": _iconImageView };
        
    NSDictionary *metrics = @{@"iconsize": @(SuggestionsTableViewCellIconSize) };
        
    // Horizontal spacing
    NSArray *horizConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[icon(iconsize)]-16-[title]-[subtitle]-|"
                                                                        options:0
                                                                        metrics:metrics
                                                                          views:views];
    [self.contentView addConstraints:horizConstraints];
                
    // Vertically constrain centers of each element
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0
                                                                  constant:0]];
        
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_subtitleLabel
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0
                                                                  constant:0]];
        
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_iconImageView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0
                                                                  constant:0]];
}

@end
