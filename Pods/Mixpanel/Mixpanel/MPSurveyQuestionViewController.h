#import <UIKit/UIKit.h>

#import "MPSurveyQuestion.h"

@protocol MPSurveyQuestionViewControllerDelegate;

@interface MPSurveyQuestionViewController : UIViewController

@property(nonatomic,assign) id<MPSurveyQuestionViewControllerDelegate> delegate;
@property(nonatomic,retain) MPSurveyQuestion *question;
@property(nonatomic,retain) UIColor *highlightColor;

@end

@protocol MPSurveyQuestionViewControllerDelegate <NSObject>
- (void)questionController:(MPSurveyQuestionViewController *)controller didReceiveAnswerProperties:(NSDictionary *)properties;
@end
