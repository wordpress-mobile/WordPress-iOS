#import "StatsTodayYesterdayButtonCell.h"

@interface StatsTodayYesterdayButtonCell ()

@property (nonatomic, weak) id<StatsTodayYesterdayButtonCellDelegate> delegate;
@property (nonatomic, assign) StatsSection currentSection;

@end

@implementation StatsTodayYesterdayButtonCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self addSegmentWithTitle:NSLocalizedString(@"Today", @"Select today's data for a stats section")];
        [self addSegmentWithTitle:NSLocalizedString(@"Yesterday", @"Select yesterday's data for a stats section")];
    }
    return self;
}

- (void)setupForSection:(StatsSection)section delegate:(id<StatsTodayYesterdayButtonCellDelegate>)delegate todayActive:(BOOL)todayActive {
    self.currentSection = section;
    self.delegate = delegate;
    self.segmentedControl.selectedSegmentIndex = todayActive ? 0 : 1;
}

- (void)segmentChanged:(UISegmentedControl *)sender {
    BOOL todaySelected = (sender.selectedSegmentIndex == 0);
    [self.delegate statsDayChangedForSection:self.currentSection todaySelected:todaySelected];
}

- (void)prepareForReuse {
    // Subclass
    // Don't remove the buttons
}

@end
