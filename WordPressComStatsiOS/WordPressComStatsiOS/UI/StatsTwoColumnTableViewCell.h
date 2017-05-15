#import "StatsSelectableTableViewCell.h"
#import "StatsStandardBorderedTableViewCell.h"

typedef NS_ENUM(NSInteger, StatsTwoColumnTableViewCellSelectType) {
    StatsTwoColumnTableViewCellSelectTypeCategory,
    StatsTwoColumnTableViewCellSelectTypeDetail,
    StatsTwoColumnTableViewCellSelectTypeTag,
    StatsTwoColumnTableViewCellSelectTypeURL
};

@interface StatsTwoColumnTableViewCell : StatsStandardBorderedTableViewCell

@property (nonatomic, copy) NSString *leftText;
@property (nonatomic, copy) NSString *rightText;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, assign) BOOL showCircularIcon;
@property (nonatomic, assign) NSUInteger indentLevel;
@property (nonatomic, assign) BOOL selectable;
@property (nonatomic, assign) StatsTwoColumnTableViewCellSelectType selectType;
@property (nonatomic, assign) BOOL indentable;
@property (nonatomic, assign) BOOL expandable;
@property (nonatomic, assign) BOOL expanded;

- (void)doneSettingProperties;

@end
