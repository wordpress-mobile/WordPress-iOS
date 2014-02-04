#import <UIKit/UIKit.h>

#import "MPSurveyQuestion.h"

@protocol MPSurveyQuestionViewControllerDelegate;

@interface MPSurveyQuestionViewController : UIViewController

@property (nonatomic, weak) id<MPSurveyQuestionViewControllerDelegate> delegate;
@property (nonatomic, strong) MPSurveyQuestion *question;
@property (nonatomic, strong) UIColor *highlightColor;

@end

@protocol MPSurveyQuestionViewControllerDelegate <NSObject>
- (void)questionController:(MPSurveyQuestionViewController *)controller didReceiveAnswerProperties:(NSDictionary *)properties;

@end
