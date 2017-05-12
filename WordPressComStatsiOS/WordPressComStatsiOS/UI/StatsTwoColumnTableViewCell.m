#import "Logging.h"
#import "StatsTwoColumnTableViewCell.h"
#import "WPStyleGuide+Stats.h"
#import <WordPressShared/WPImageSource.h>
#import "StatsBorderedCellBackgroundView.h"
#import <QuartzCore/QuartzCore.h>
#import "WPStyleGuide+Stats.h"
#import "NSBundle+StatsBundleHelper.h"

@interface StatsTwoColumnTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *leftLabel;
@property (nonatomic, weak) IBOutlet UILabel *rightLabel;
@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak) IBOutlet UIImageView *leftHandGlyph;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *widthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *spaceConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *leadingEdgeConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *rightEdgeConstraint;

@end

@implementation StatsTwoColumnTableViewCell

- (void)doneSettingProperties
{
    self.leftLabel.text = self.leftText;
    self.rightLabel.text = self.rightText;
    self.leftHandGlyph.hidden = !self.expandable && self.selectType == StatsTwoColumnTableViewCellSelectTypeDetail;

    if (self.selectable) {
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
        self.rightEdgeConstraint.constant = 8.0f;
        self.leftLabel.textColor = [WPStyleGuide wordPressBlue];
        
        if (self.expandable == NO) {
            self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            self.rightEdgeConstraint.constant = -2.0f;
        } else {
            self.accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8.0f, 13.0f)];
        }
    }
    
    self.iconImageView.image = nil;

    // Hide the image if one isn't set
    if (self.imageURL) {
        if (self.showCircularIcon) {
            self.iconImageView.layer.cornerRadius = 10.0f;
            self.iconImageView.layer.masksToBounds = YES;
            [self.iconImageView.layer setNeedsDisplay];
        }

        [[WPImageSource sharedSource] downloadImageForURL:self.imageURL withSuccess:^(UIImage *image) {
            self.iconImageView.image = image;
            self.iconImageView.backgroundColor = [UIColor clearColor];
        } failure:^(NSError *error) {
            DDLogWarn(@"Unable to download icon %@", error);
        }];
    } else {
        self.iconImageView.hidden = YES;
        self.widthConstraint.constant = 0.0f;
        self.spaceConstraint.constant = 0.0f;
    }
    
    BOOL isNestedRow = self.indentLevel > 1;
    if (isNestedRow || self.expanded) {
        StatsBorderedCellBackgroundView *backgroundView = (StatsBorderedCellBackgroundView *)self.backgroundView;
        backgroundView.contentBackgroundView.backgroundColor = [WPStyleGuide statsNestedCellBackground];
    }
    
    NSBundle *statsBundle = [NSBundle statsBundle];

    if (self.expandable && self.expanded) {
        self.leftHandGlyph.image = [[UIImage imageNamed:@"icon-chevron-up-20x20" inBundle:statsBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    } else if (self.expandable && !self.expanded){
        self.leftHandGlyph.image = [[UIImage imageNamed:@"icon-chevron-down-20x20" inBundle:statsBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    } else if (self.selectType == StatsTwoColumnTableViewCellSelectTypeURL) {
        self.leftHandGlyph.image = [[UIImage imageNamed:@"icon-share-20x20" inBundle:statsBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    } else if (self.selectType == StatsTwoColumnTableViewCellSelectTypeTag) {
        self.leftHandGlyph.image =  [[UIImage imageNamed:@"icon-tag-20x20" inBundle:statsBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    } else if (self.selectType == StatsTwoColumnTableViewCellSelectTypeCategory) {
        self.leftHandGlyph.image =  [[UIImage imageNamed:@"icon-folder-20x20" inBundle:statsBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    self.leftHandGlyph.tintColor = self.leftLabel.textColor;
    
    CGFloat indentWidth = self.indentable ? self.indentLevel * 8.0f + 15.0f : 20.0f;
    // Account for chevron or link icon or if its a nested row
    indentWidth += !self.leftHandGlyph.hidden || self.indentLevel > 1 ? 28.0f : 0.0f;
    self.leadingEdgeConstraint.constant = indentWidth;
    
    [self setNeedsUpdateConstraints];
}


- (void)prepareForReuse
{
    [super prepareForReuse];

    self.leftLabel.text = nil;
    self.rightLabel.text = nil;
    self.leftLabel.textColor = [UIColor blackColor];
    self.iconImageView.image = nil;
    
    self.iconImageView.hidden = NO;
    self.widthConstraint.constant = 20.0f;
    self.spaceConstraint.constant = 8.0f;
    self.leadingEdgeConstraint.constant = 43.0f;
    self.rightEdgeConstraint.constant = 23.0f;
    StatsBorderedCellBackgroundView *backgroundView = (StatsBorderedCellBackgroundView *)self.backgroundView;
    backgroundView.contentBackgroundView.backgroundColor = [UIColor whiteColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryType = UITableViewCellAccessoryNone;
    self.accessoryView = nil;
    self.selectType = StatsTwoColumnTableViewCellSelectTypeDetail;
 
    self.showCircularIcon = NO;
    self.iconImageView.layer.cornerRadius = 0.0f;
    self.iconImageView.layer.masksToBounds = NO;
    [self.iconImageView.layer setNeedsDisplay];
}


- (void)setExpanded:(BOOL)expanded
{
    _expanded = expanded;
    
    self.topBorderDarkEnabled = expanded;
}

@end
