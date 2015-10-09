#import "MenusSelectionCell.h"
#import "WPStyleGuide.h"

CGFloat const MenusSelectionCellDefaultHeight = 70;

@implementation MenusSelectionCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self) {
        self.textLabel.numberOfLines = 2;
    }
    
    return self;
}

- (NSString *)selectionSubtitleText
{
    return nil;
}

- (NSString *)selectionTitleText
{
    return nil;
}

- (NSAttributedString *)attributedDisplayText
{
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] init];
    {
        NSDictionary *attributes =  @{NSFontAttributeName: [WPStyleGuide subtitleFont], NSForegroundColorAttributeName: [WPStyleGuide grey]};
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:[self selectionSubtitleText] attributes:attributes];
        [mutableAttributedString appendAttributedString:attributedString];
    }
    [mutableAttributedString.mutableString appendString:@"\n"];
    {
        NSDictionary *attributes =  @{NSFontAttributeName: [WPStyleGuide regularTextFontSemiBold], NSForegroundColorAttributeName: [WPStyleGuide darkGrey]};
        NSString *string = [self selectionTitleText];
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
        [mutableAttributedString appendAttributedString:attributedString];
    }
    
    return mutableAttributedString;
}

@end
