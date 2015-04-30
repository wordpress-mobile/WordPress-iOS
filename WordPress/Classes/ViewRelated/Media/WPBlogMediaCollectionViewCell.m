#import "WPBlogMediaCollectionViewCell.h"

@interface WPBlogMediaCollectionViewCell ()

@property (nonatomic, strong) UILabel * positionLabel;
@property (nonatomic, strong) UIView * selectionFrame;
@property (nonatomic, strong) UIImageView * imageView;
@property (nonatomic, strong) UILabel * captionLabel;

@end

@implementation WPBlogMediaCollectionViewCell


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self){
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        [self commonInit];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self setImage:nil];
    [self setCaption:@""];
    [self setPosition:NSNotFound];
}

- (void)commonInit
{
    _imageView = [[UIImageView alloc] init];
    self.backgroundView = _imageView;

    _selectionFrame = [[UIView alloc] initWithFrame:self.backgroundView.frame];
    _selectionFrame.layer.borderColor = [[self tintColor] CGColor];
    _selectionFrame.layer.borderWidth = 3;
    
    CGFloat counterTextSize = [UIFont smallSystemFontSize];
    CGFloat labelSize = (counterTextSize*2)+2;
    _positionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,labelSize,labelSize)];
    _positionLabel.backgroundColor = [self tintColor];
    _positionLabel.textColor = [UIColor whiteColor];
    _positionLabel.textAlignment = NSTextAlignmentCenter;
    _positionLabel.font = [UIFont systemFontOfSize:counterTextSize];
    
    [_selectionFrame addSubview:_positionLabel];
    
    self.selectedBackgroundView = _selectionFrame;
    
    _captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,self.contentView.frame.size.height-counterTextSize,self.contentView.frame.size.width,counterTextSize)];
    _captionLabel.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.7];
    _captionLabel.hidden = YES;
    _captionLabel.textColor = [UIColor whiteColor];
    _captionLabel.textAlignment = NSTextAlignmentRight;
    _captionLabel.font = [UIFont systemFontOfSize:counterTextSize-2];
    [self.contentView addSubview:_captionLabel];
    
    
}

- (void)setImage:(UIImage *) image
{
    self.imageView.image = image;
}

- (void)setPosition:(NSInteger) position
{
    _position = position;
    self.positionLabel.hidden = position == NSNotFound;
    self.positionLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)(position)];
}

- (void)setCaption:(NSString *) caption
{
    self.captionLabel.hidden = !(caption.length > 0);
    self.captionLabel.text = caption;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (self.isSelected){
        _captionLabel.backgroundColor = [self tintColor];
    } else {
        self.positionLabel.hidden = YES;
        _captionLabel.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.7];
    }

}

- (void)tintColorDidChange
{
    [super tintColorDidChange];
    _selectionFrame.layer.borderColor = [[self tintColor] CGColor];
    _positionLabel.backgroundColor = [self tintColor];
    if (self.isSelected){
        _captionLabel.backgroundColor = [self tintColor];
    } else {
        _captionLabel.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.7];
    }
}

@end
