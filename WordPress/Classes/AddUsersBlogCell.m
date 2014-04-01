#import "AddUsersBlogCell.h"
#import "UIImageView+Gravatar.h"

@interface AddUsersBlogCell() {
    UILabel *_titleLabel;
    UIImageView *_blavatarImage;
    UIImageView *_checkboxImage;
    UIImageView *_separator;
    UIImageView *_topSeparator;
    
    NSString *_blavatarUrl;
}

@end

@implementation AddUsersBlogCell

CGFloat const AddUsersBlogCellMaxTextWidth = 208.0;
CGFloat const AddUsersBlogCellBlavatarSide = 32.0;
CGFloat const AddUsersBlogCellMinimumHeight = 48.0;
CGFloat const AddUsersBlogCellStandardOffset = 16.0;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = [UIFont fontWithName:@"OpenSans" size:15.0];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.numberOfLines = 0;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self addSubview:_titleLabel];
        
        _blavatarImage = [[UIImageView alloc] initWithFrame:CGRectMake(AddUsersBlogCellStandardOffset, 0.5*AddUsersBlogCellStandardOffset, AddUsersBlogCellBlavatarSide, AddUsersBlogCellBlavatarSide)];
        [self addSubview:_blavatarImage];
        
        UIImage *image = [UIImage imageNamed:@"icon-check-small-blue"];
        _checkboxImage = [[UIImageView alloc] initWithImage:image];
        _checkboxImage.frame = CGRectMake(CGRectGetWidth(self.bounds) - AddUsersBlogCellStandardOffset - CGRectGetWidth(_checkboxImage.frame), AddUsersBlogCellStandardOffset, image.size.width , image.size.height);
        [self addSubview:_checkboxImage];
        
        _topSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line"]];
        _topSeparator.frame = CGRectZero;
        [self addSubview:_topSeparator];
        
        _separator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line"]];
        [self addSubview:_separator];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat x,y;
    CGFloat cellWidth = CGRectGetWidth(self.bounds);
    CGFloat cellHeight = CGRectGetHeight(self.bounds);
    
    CGSize textSize = [[self class] sizeForText:_titleLabel.text];
    CGFloat rowHeight = [[self class] rowHeightForTextWithSize:textSize];
    
    // Setup Blavatar
    x = AddUsersBlogCellStandardOffset;
    y = (rowHeight - AddUsersBlogCellBlavatarSide)/2.0;
    _blavatarImage.frame = CGRectIntegral(CGRectMake(x, y, AddUsersBlogCellBlavatarSide, AddUsersBlogCellBlavatarSide));
    NSURL *blogURL = [NSURL URLWithString:_blavatarUrl];
    [_blavatarImage setImageWithBlavatarUrl:[blogURL host] isWPcom:self.isWPCom];
    
    // Setup Checkbox
    x = cellWidth - AddUsersBlogCellStandardOffset - CGRectGetWidth(_checkboxImage.frame);
    y = (rowHeight - _checkboxImage.image.size.height)/2.0;
    _checkboxImage.frame = CGRectIntegral(CGRectMake(x, y, _checkboxImage.image.size.width, _checkboxImage.image.size.height));
    
    // Setup Title
    x = CGRectGetMaxX(_blavatarImage.frame) + AddUsersBlogCellStandardOffset;
    y = (rowHeight - textSize.height)/2.0;
    if (self.selected) {
        _titleLabel.textColor = [UIColor whiteColor];
    } else {
        _titleLabel.textColor = [UIColor colorWithRed:188.0/255.0 green:221.0/255.0 blue:236.0/255.0 alpha:1.0];
    }
    _titleLabel.frame = CGRectIntegral(CGRectMake(x, y, textSize.width, textSize.height));
    
    // Setup Separators
    _separator.frame = CGRectMake(AddUsersBlogCellStandardOffset, cellHeight - 2, cellWidth - AddUsersBlogCellStandardOffset, 1);
    
    if (_showTopSeparator) {
        _topSeparator.frame = CGRectMake(AddUsersBlogCellStandardOffset, 0, cellWidth - AddUsersBlogCellStandardOffset, 1);
    } else {
        _topSeparator.frame = CGRectZero;
    }
}

- (void)setTitle:(NSString *)title
{
    _titleLabel.text = title;
    [self setNeedsLayout];
}

- (void)setBlavatarUrl:(NSString *)url
{
    if (_blavatarUrl != url) {
        _blavatarUrl = url;
        [self setNeedsLayout];
    }
}

- (void)setShowTopSeparator:(BOOL)showTopSeparator
{
    _showTopSeparator = showTopSeparator;
    [self setNeedsLayout];
}

+ (CGFloat)rowHeightWithText:(NSString *)text
{
    CGSize textSize = [self sizeForText:text];
    return [self rowHeightForTextWithSize:textSize];
}

- (void)hideCheckmark:(BOOL)hide
{
	_checkboxImage.hidden = hide;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];

    UIImage *image;
    if (self.selected) {
        image = [UIImage imageNamed:@"icon-check-small-white"];
    } else {
        image = [UIImage imageNamed:@"icon-check-small-blue"];
    }
    _checkboxImage.image = image;
}

#pragma mark - Private Methods

+ (CGFloat)rowHeightForTextWithSize:(CGSize)size
{
    if (size.height > AddUsersBlogCellBlavatarSide) {
        CGFloat blavatarStartY = 0.5*AddUsersBlogCellMinimumHeight;
        return blavatarStartY + size.height;
    } else {
        return AddUsersBlogCellMinimumHeight;
    }
}

+ (CGSize)sizeForText:(NSString *)text
{
    UIFont *titleFont = [UIFont fontWithName:@"OpenSans" size:15.0];
    return [text suggestedSizeWithFont:titleFont width:AddUsersBlogCellMaxTextWidth];
}

@end
