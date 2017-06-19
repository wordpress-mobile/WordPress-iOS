#import "WPStatsContributionGraph.h"
#import "WPStyleGuide+Stats.h"
#import <objc/runtime.h>
@import WordPressShared;
@import WordPressKit;

static const NSInteger DefaultGradeCount = 5;
static const CGFloat DefaultCellSize = 12.0;
static const CGFloat DefaultCellSpacing = 3.0;
static NSString *const ClearPostActivityDateNotification = @"ClearPostActivityDate";

@interface WPStatsContributionGraph ()

@property (nonatomic) NSUInteger gradeCount;
@property (nonatomic, strong) NSMutableArray *gradeMinimumCutoff;
@property (nonatomic, strong) NSMutableArray *colors;
@property (nonatomic, strong) NSMutableArray *dateButtons;

@end

@implementation WPStatsContributionGraph

- (void)awakeFromNib
{
    [super awakeFromNib];
    _dateButtons = [NSMutableArray array];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    __weak __typeof(self) weakSelf = self;
    [nc addObserverForName: ClearPostActivityDateNotification
                    object: nil
                     queue: [NSOperationQueue mainQueue]
                usingBlock: ^(NSNotification *notification) {
                    [weakSelf clearAllButtons];
                }];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Load one-time setup data from the delegate
- (void)loadDefaults
{
    self.opaque = NO;
    
    // Get the total number of grades
    if ([self.delegate respondsToSelector:@selector(numberOfGrades)]) {
        self.gradeCount = [self.delegate numberOfGrades];
    }
    else {
        self.gradeCount = DefaultGradeCount;
    }
    
    // Load all of the colors from the delegate
    if ([self.delegate respondsToSelector:@selector(colorForGrade:)]) {
        self.colors = [[NSMutableArray alloc] initWithCapacity:self.gradeCount];
        for (int i = 0; i < self.gradeCount; i++) {
            [self.colors addObject:[self.delegate colorForGrade:i]];
        }
    }
    else {
        // Not implemented in the delegate, use the defaults
        self.colors = [[NSMutableArray alloc] initWithObjects:
                       [UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1],
                       [UIColor colorWithRed:0.839 green:0.902 blue:0.522 alpha:1],
                       [UIColor colorWithRed:0.549 green:0.776 blue:0.396 alpha:1],
                       [UIColor colorWithRed:0.267 green:0.639 blue:0.251 alpha:1],
                       [UIColor colorWithRed:0.118 green:0.408 blue:0.137 alpha:1], nil];
        
        // Check if there is the correct number of colors
        if (self.gradeCount != DefaultGradeCount) {
            [[NSException exceptionWithName:@"Invalid Data" reason:@"The number of grades does not match the number of colors. Implement colorForGrade: to define a different number of colors than the default 5" userInfo:NULL] raise];
        }
    }
    
    // Get the minimum cutoff for each grade
    if ([self.delegate respondsToSelector:@selector(minimumValueForGrade:)]) {
        self.gradeMinimumCutoff = [[NSMutableArray alloc] initWithCapacity:self.gradeCount];
        for (int i = 0; i < self.gradeCount; i++) {
            [self.gradeMinimumCutoff addObject:@([self.delegate minimumValueForGrade:i])];
        }
    }
    else {
        // Use the minimum cuttoff default values
        self.gradeMinimumCutoff = [[NSMutableArray alloc] initWithObjects:
                                   @0,
                                   @1,
                                   @3,
                                   @6,
                                   @8, nil];
        
        if (_gradeCount != DefaultGradeCount) {
            [[NSException exceptionWithName:@"Invalid Data" reason:@"The number of grades does not match the number of grade cutoffs. Implement minimumValueForGrade: to define the correct number of cutoff values" userInfo:NULL] raise];
        }
    }
    
    if (!self.monthForGraph) {
        // Use the current month by default if no month is defined.
        self.monthForGraph = [NSDate date];
    }
    
    // Initialize with the default size and spacing
    self.cellSpacing = DefaultCellSpacing;
    self.cellSize = DefaultCellSize;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [self.dateButtons removeAllObjects];
    NSInteger columnCount = 0;
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [calendar setFirstWeekday:2]; // Sunday == 1, Saturday == 7...Make the first day of the week Monday
    NSDateComponents *comp = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:self.monthForGraph];
    comp.day = 1;
    NSDate *firstDay = [calendar dateFromComponents:comp];
    comp.month = comp.month + 1;
    NSDate *nextMonth = [calendar dateFromComponents:comp];
    
    NSDictionary *dayNumberTextAttributes = nil;
    if (self.showDayNumbers) {
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.alignment = NSTextAlignmentLeft;
        dayNumberTextAttributes = @{
                                    NSFontAttributeName: [WPFontManager systemLightFontOfSize:self.cellSize * 0.4],
                                    NSParagraphStyleAttributeName: paragraphStyle
                                    };
    }
    
    for (NSDate *date = firstDay; [date compare:nextMonth] == NSOrderedAscending; date = [self getDateAfterDate:date]) {
        NSDateComponents *comp = [calendar components:NSCalendarUnitDay fromDate:date];
        NSInteger day = comp.day;
        // These two calls will ensure the proper values for weekday & week of month are returned
        // since we are starting the week on a Monday instead of a Sunday
        NSInteger weekday = [calendar ordinalityOfUnit:NSCalendarUnitWeekday inUnit:NSCalendarUnitWeekOfMonth forDate:date];;
        NSInteger weekOfMonth = [calendar ordinalityOfUnit:NSCalendarUnitWeekOfMonth inUnit:NSCalendarUnitMonth forDate:date];;
        
        NSInteger grade = 0;
        NSInteger contributions = 0;
        if (self.graphData && self.graphData.items) {
            for (StatsStreakItem *item in self.graphData.items) {
                if (item.date) {
                    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                    NSDateComponents *components1 = [gregorian components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:item.date];
                    NSDateComponents *components2 = [gregorian components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
                    if (components1.month == components2.month && components1.year == components2.year && components1.day == components2.day) {
                        contributions++;
                    }
                }
            }
        }
        
        // Get the grade from the minimum cutoffs
        for (int i = 0; i < self.gradeCount; i++) {
            if ([self.gradeMinimumCutoff[i] integerValue] <= contributions) {
                grade = i;
            }
        }
        
        [self.colors[grade] setFill];
        
        CGFloat column = (weekOfMonth - 1) * (self.cellSize + self.cellSpacing);
        CGFloat row = (weekday - 1) * (self.cellSize + self.cellSpacing);
        CGRect backgroundRect = CGRectMake(column, row, self.cellSize, self.cellSize);
        CGContextFillRect(context, backgroundRect);
        
        if (self.showDayNumbers) {
            NSString *string = [NSString stringWithFormat:@"%ld", (long)day];
            [string drawInRect:backgroundRect withAttributes:dayNumberTextAttributes];
        }
        
        if ([self.delegate respondsToSelector:@selector(dateTapped:)]) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.frame = backgroundRect;
            [button setImage:[UIImage imageWithColor:[UIColor clearColor] havingSize:backgroundRect.size] forState:UIControlStateNormal];
            [button setImage:[UIImage imageWithColor:[WPStyleGuide statsLighterOrange] havingSize:backgroundRect.size] forState:UIControlStateHighlighted];
            [button setImage:[UIImage imageWithColor:[WPStyleGuide statsDarkerOrange] havingSize:backgroundRect.size] forState:UIControlStateSelected];
            [button addTarget:self action:@selector(daySelected:) forControlEvents:UIControlEventTouchUpInside];
            
            NSDictionary *data = @{
                                   @"date": date,
                                   @"value": @(contributions)
                                   };
            objc_setAssociatedObject(button, @"dynamic_key", data, OBJC_ASSOCIATION_COPY);
            [self addSubview:button];
            [self.dateButtons addObject:button];
        }
        
        columnCount = (columnCount < weekOfMonth) ? weekOfMonth : columnCount;
    }

    // Draw the abbreviated month name below the graph
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setLocalizedDateFormatFromTemplate:@"MMM"];
    NSString *monthName = [formatter stringFromDate:self.monthForGraph];
    CGRect labelRect = CGRectMake( (((self.cellSize * columnCount)/2.0)-(self.cellSize/1.1)), self.cellSize * 9.0, self.cellSize * 3.0, self.cellSize * 1.2);
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByClipping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributes = @{
                                 NSFontAttributeName: [WPFontManager systemRegularFontOfSize:13.0],
                                 NSForegroundColorAttributeName: [WPStyleGuide statsDarkGray],
                                 NSParagraphStyleAttributeName: paragraphStyle,
                                 };
    [[monthName uppercaseString] drawInRect:labelRect withAttributes:attributes];
}

#pragma mark - Setters

- (void)setDelegate:(id<WPStatsContributionGraphDelegate>)delegate
{
    _delegate = delegate;
    [self loadDefaults];
    [self setNeedsDisplay];
}

- (void)setCellSize:(CGFloat)cellSize
{
    _cellSize = cellSize;
}

- (void)setCellSpacing:(CGFloat)cellSpacing
{
    _cellSpacing = cellSpacing;
}

- (void)setShowDayNumbers:(BOOL)showDayNumbers
{
    _showDayNumbers = showDayNumbers;
    [self setNeedsDisplay];
}

- (void)setMonthForGraph:(NSDate *)monthForGraph
{
    _monthForGraph = monthForGraph;
    [self setNeedsDisplay];
}

- (void)setGraphData:(StatsStreak *)graphData
{
    _graphData = graphData;
    [self setNeedsDisplay];
}

#pragma mark - Privates

- (NSDate *)getDateAfterDate:(NSDate *)date
{
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.day = 1;
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    return [calendar dateByAddingComponents:components toDate:date options:0];
}

- (void)daySelected:(id)sender
{
    // Clear all the already-selected buttons
    [[NSNotificationCenter defaultCenter] postNotificationName:ClearPostActivityDateNotification object:self];
    
    UIButton *selectedButton = (UIButton*)sender;
    selectedButton.selected = !selectedButton.selected;
    
    NSDictionary *data = (NSDictionary *)objc_getAssociatedObject(sender, @"dynamic_key");
    if ([self.delegate respondsToSelector:@selector(dateTapped:)]) {
        [self.delegate dateTapped:data];
    }
}

- (void)clearAllButtons
{
    for (UIButton *button in self.dateButtons) {
        button.selected = NO;
    }
}

@end
