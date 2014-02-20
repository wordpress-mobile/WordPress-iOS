#import <UIKit/UIKit.h>

#import "Mixpanel.h"
#import "MPSurvey.h"

@protocol MPSurveyNavigationControllerDelegate;

@interface MPSurveyNavigationController : UIViewController

@property (nonatomic, strong) MPSurvey *survey;
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, weak) id<MPSurveyNavigationControllerDelegate> delegate;

@end

@protocol MPSurveyNavigationControllerDelegate <NSObject>

- (void)surveyController:(MPSurveyNavigationController *)controller wasDismissedWithAnswers:(NSArray *)answers;

@end
