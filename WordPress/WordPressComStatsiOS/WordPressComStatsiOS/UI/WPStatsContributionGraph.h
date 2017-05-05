#import <UIKit/UIKit.h>
#import "StatsStreak.h"

@protocol WPStatsContributionGraphDelegate <NSObject>

@optional
/**
 @description   The total number of grades in the graph. If this method isn't implemented,
                the default value of 5 is used.
 @returns       An NSUInteger that specifies the total number of color divides in the graph.
 */
- (NSUInteger)numberOfGrades;

/**
 @description   The single color assigned to each grade. If this method isn't implemented,
                the default 5 color scheme is used.
 @param grade   The grade index starting at zero to the numberOfGrades-1
 @returns       A UIColor for the specified grade.
 */
- (UIColor *)colorForGrade:(NSUInteger)grade;

/**
 @description   Defines how values are translated into grades If this method isn't implemented,
                the default values are used.
 @param grade   The grade starting at zero to the numberOfGrades-1
 @returns       An NSUInteger that specifies the minimum cutoff for a grade
 */
- (NSInteger)minimumValueForGrade:(NSUInteger)grade;


/**
 @description   Called when
 @returns       A NSDictionary that contains the date and number of posts on that day.
 */
- (void)dateTapped:(NSDictionary *)dict;

@end

@interface WPStatsContributionGraph : UIView

#pragma mark - Properties

@property (nonatomic, weak) IBOutlet id<WPStatsContributionGraphDelegate> delegate;
@property (nonatomic) CGFloat cellSize;
@property (nonatomic) CGFloat cellSpacing;

/**
 @description   A BOOL when set to YES will display the day number within each cell. Default is NO.
 */
@property (nonatomic) BOOL showDayNumbers;

/**
 @description   A NSDate in month that the graph should display
 */
@property (nonatomic, strong) NSDate *monthForGraph;

/**
 @description   Values used to populate this graph
 */
@property (nonatomic, strong) StatsStreak *graphData;

@end
