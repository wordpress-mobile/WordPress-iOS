#import <UIKit/UIKit.h>

#import "Mixpanel.h"
#import "MPSurvey.h"

@protocol MPSurveyNavigationControllerDelegate;

@interface MPSurveyNavigationController : UIViewController

@property(nonatomic,retain) MPSurvey *survey;
@property(nonatomic,retain) UIImage *backgroundImage;
@property(nonatomic,assign) id<MPSurveyNavigationControllerDelegate> delegate;

@end

@protocol MPSurveyNavigationControllerDelegate <NSObject>
- (void)surveyControllerWasDismissed:(MPSurveyNavigationController *)controller withAnswers:(NSArray *)answers;
@end
