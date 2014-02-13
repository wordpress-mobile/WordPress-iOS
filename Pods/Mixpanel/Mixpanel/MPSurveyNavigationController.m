#import <QuartzCore/QuartzCore.h>

#import "MPSurvey.h"
#import "MPSurveyNavigationController.h"
#import "MPSurveyQuestion.h"
#import "MPSurveyQuestionViewController.h"
#import "UIImage+MPAverageColor.h"
#import "UIImage+MPImageEffects.h"
#import "UIView+MPSnapshotImage.h"

@interface MPSurveyNavigationController () <MPSurveyQuestionViewControllerDelegate>

@property(nonatomic,retain) IBOutlet UIImageView *view;
@property(nonatomic,retain) IBOutlet UIColor *highlightColor;
@property(nonatomic,retain) IBOutlet UIView *containerView;
@property(nonatomic,retain) IBOutlet UILabel *pageNumberLabel;
@property(nonatomic,retain) IBOutlet UIButton *nextButton;
@property(nonatomic,retain) IBOutlet UIButton *previousButton;
@property(nonatomic,retain) IBOutlet UIImageView *logo;
@property(nonatomic,retain) IBOutlet UIButton *exitButton;
@property(nonatomic,retain) IBOutlet UIView *header;
@property(nonatomic,retain) IBOutlet UIView *footer;
@property(nonatomic,retain) NSMutableArray *questionControllers;
@property(nonatomic) UIViewController *currentQuestionController;
@property(nonatomic,retain) NSMutableDictionary *answers;

@end

@implementation MPSurveyNavigationController

- (void)dealloc
{
    self.survey = nil;
    self.backgroundImage = nil;
    self.questionControllers = nil;
    self.answers = nil;
    self.highlightColor = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.image = [_backgroundImage mp_applyDarkEffect];

    // set highlight color based on average background color
    UIColor *avgColor = [_backgroundImage mp_averageColor];
    CGFloat hue;
    CGFloat brightness;
    CGFloat saturation;
    CGFloat alpha;
    if ([avgColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        avgColor = [UIColor colorWithHue:hue saturation:0.8f brightness:brightness alpha:alpha];
    }
    self.highlightColor = avgColor;
    self.questionControllers = [NSMutableArray array];
    self.answers = [NSMutableDictionary dictionary];
    for (NSUInteger i = 0; i < _survey.questions.count; i++) {
        [_questionControllers addObject:[NSNull null]];
    }
    [self loadQuestion:0];
    [self loadQuestion:1];
    MPSurveyQuestionViewController *firstQuestionController = _questionControllers[0];
    [self addChildViewController:firstQuestionController];
    [_containerView addSubview:firstQuestionController.view];
    [self constrainQuestionView:firstQuestionController.view];
    [firstQuestionController didMoveToParentViewController:self];
    _currentQuestionController = firstQuestionController;
    [firstQuestionController.view setNeedsUpdateConstraints];
    [self updatePageNumber:0];
    [self updateButtons:0];
}

- (void)beginAppearanceTransition:(BOOL)isAppearing animated:(BOOL)animated
{
    [super beginAppearanceTransition:isAppearing animated:animated];
    if (isAppearing) {
        _header.alpha = 0;
        _containerView.alpha = 0;
        _footer.alpha = 0;
    }
}

- (void)endAppearanceTransition
{
    [super endAppearanceTransition];
    NSTimeInterval duration = 0.25;
    _header.alpha = 1;
    _containerView.alpha = 1;
    _footer.alpha = 1;
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         NSArray *keyTimes = @[@0, @0.3, @1];

                         // slide header down
                         CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
                         anim.duration = duration;
                         anim.keyTimes = keyTimes;
                         CGFloat y1 = _header.bounds.origin.y - _header.bounds.size.height;
                         CGFloat y2 = _header.bounds.origin.y;
                         anim.values = @[@(y1), @(y2), @(y2)];
                         [_header.layer addAnimation:anim forKey:nil];

                         // slide question container and footer up
                         anim = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
                         anim.duration = duration;
                         anim.keyTimes = keyTimes;
                         y1 = _containerView.bounds.origin.y + _containerView.bounds.size.height + _footer.bounds.size.height;
                         y2 = _containerView.bounds.origin.y;
                         anim.values = @[@(y1), @(y1), @(y2)];
                         [_containerView.layer addAnimation:anim forKey:nil];

                         anim = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
                         anim.duration = duration;
                         anim.keyTimes = keyTimes;
                         y1 = _footer.bounds.origin.y + _containerView.bounds.size.height + _footer.bounds.size.height;
                         y2 = _footer.bounds.origin.y;
                         anim.values = @[@(y1), @(y1), @(y2)];
                         [_footer.layer addAnimation:anim forKey:nil];

                     }
                     completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}

- (void)updatePageNumber:(NSUInteger)index
{
    _pageNumberLabel.text = [NSString stringWithFormat:@"%lu of %lu", (unsigned long)(index + 1), (unsigned long)[_survey.questions count]];
}

- (void)updateButtons:(NSUInteger)index
{
    _previousButton.enabled = index > 0;
    _nextButton.enabled = index < ([_survey.questions count] - 1);
}

- (void)loadQuestion:(NSUInteger)index
{
    if (index < _survey.questions.count) {
        MPSurveyQuestionViewController *controller = _questionControllers[index];
        // replace the placeholder if necessary
        if ((NSNull *)controller == [NSNull null]) {
            MPSurveyQuestion *question = _survey.questions[index];
            NSString *storyboardIdentifier = [NSString stringWithFormat:@"%@ViewController", NSStringFromClass([question class])];
            controller = [self.storyboard instantiateViewControllerWithIdentifier:storyboardIdentifier];
            if (controller) {
                controller.delegate = self;
                controller.question = question;
                controller.highlightColor = _highlightColor;
                controller.view.translatesAutoresizingMaskIntoConstraints = NO; // we contrain with auto layout in constrainQuestionView:
                _questionControllers[index] = controller;
            } else {
                NSLog(@"no view controller for storyboard identifier: %@", storyboardIdentifier);
            }
        }
    }
}

- (void)constrainQuestionView:(UIView *)view
{
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    [_containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:views]];
    [_containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:views]];
}

- (void)showQuestionAtIndex:(NSUInteger)index animatingForward:(BOOL)forward
{
    if (index < [_survey.questions count]) {

        UIViewController *fromController = _currentQuestionController;

        [self loadQuestion:index];
        UIViewController *toController = _questionControllers[index];

        [fromController willMoveToParentViewController:nil];
        [self addChildViewController:toController];

        // reset after being faded out last time
        toController.view.alpha = 1;

        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];

        NSTimeInterval duration = 0.25;
        [self transitionFromViewController:fromController
                          toViewController:toController
                                  duration:duration
                                   options:UIViewAnimationOptionCurveEaseIn
                                animations:^{

                                    // position to view with auto layout
                                    [self constrainQuestionView:toController.view];

                                    NSMutableArray *anims;
                                    CABasicAnimation *basicAnim;
                                    CAKeyframeAnimation *keyFrameAnim;
                                    CAAnimationGroup *group;
                                    NSArray *keyTimes;

                                    CGFloat slideDistance = _containerView.bounds.size.width * 1.3f;
                                    CGFloat dropDistance = _containerView.bounds.size.height / 4.0f;

                                    if (forward) {

                                        // from view
                                        anims = [NSMutableArray array];
                                        // slides left
                                        basicAnim = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
                                        basicAnim.byValue = @(-slideDistance);
                                        [anims addObject:basicAnim];
                                        // after a moment, rotates counterclockwise and shrinks a bit as it moves offscreen
                                        keyTimes = @[@0, @0.4, @1];
                                        keyFrameAnim = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
                                        keyFrameAnim.keyTimes = keyTimes;
                                        keyFrameAnim.values = @[@0, @0, @(-M_PI_4)];
                                        [anims addObject:keyFrameAnim];
                                        keyFrameAnim = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
                                        keyFrameAnim.keyTimes = keyTimes;
                                        keyFrameAnim.values = @[@1, @1, @0.8];
                                        [anims addObject:keyFrameAnim];
                                        group = [CAAnimationGroup animation];
                                        group.animations = anims;
                                        group.duration = duration;
                                        [fromController.view.layer addAnimation:group forKey:nil];

                                        // to view
                                        anims = [NSMutableArray array];
                                        // starts offscreen, down, to the right and rotated clockwise, then snaps into place
                                        basicAnim = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
                                        basicAnim.fromValue = @(dropDistance);
                                        basicAnim.byValue = @(-dropDistance);
                                        [anims addObject:basicAnim];
                                        basicAnim = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
                                        basicAnim.fromValue = @(slideDistance);
                                        basicAnim.byValue = @(-slideDistance);
                                        [anims addObject:basicAnim];
                                        basicAnim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
                                        basicAnim.fromValue = @(M_PI_4);
                                        basicAnim.byValue = @(-M_PI_4);
                                        [anims addObject:basicAnim];
                                        group = [CAAnimationGroup animation];
                                        group.animations = anims;
                                        group.duration = duration;
                                        [toController.view.layer addAnimation:group forKey:nil];

                                    } else {

                                        // from view
                                        anims = [NSMutableArray array];
                                        // slides right and spins and drops offscreen
                                        basicAnim = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
                                        basicAnim.byValue = @(dropDistance);
                                        [anims addObject:basicAnim];
                                        basicAnim = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
                                        basicAnim.byValue = @(slideDistance);
                                        [anims addObject:basicAnim];
                                        basicAnim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
                                        basicAnim.byValue = @(M_PI_4);
                                        [anims addObject:basicAnim];
                                        group = [CAAnimationGroup animation];
                                        group.animations = anims;
                                        group.duration = duration;
                                        [fromController.view.layer addAnimation:group forKey:nil];

                                        // to view
                                        anims = [NSMutableArray array];
                                        // slides right into place
                                        basicAnim = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
                                        basicAnim.fromValue = @(-slideDistance);
                                        basicAnim.byValue = @(slideDistance);
                                        [anims addObject:basicAnim];
                                        // grows and rotates clockwise at the beginning
                                        keyTimes = @[@0, @0.6, @1];
                                        keyFrameAnim = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
                                        keyFrameAnim.keyTimes = keyTimes;
                                        keyFrameAnim.values = @[@(-M_PI_4), @0, @0];
                                        [anims addObject:keyFrameAnim];
                                        keyFrameAnim = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
                                        keyFrameAnim.keyTimes = keyTimes;
                                        keyFrameAnim.values = @[@0.8, @1, @1];
                                        [anims addObject:keyFrameAnim];
                                        group = [CAAnimationGroup animation];
                                        group.animations = anims;
                                        group.duration = duration;
                                        [toController.view.layer addAnimation:group forKey:nil];
                                    }

                                    // hack to hide animation flashing fromController.view at the end
                                    fromController.view.alpha = 0;

                               }
                                completion:^(BOOL finished){
                                    [toController didMoveToParentViewController:self];
                                    [fromController removeFromParentViewController];
                                    _currentQuestionController = toController;
                                    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                                }];
        [self updatePageNumber:index];
        [self updateButtons:index];
        [self loadQuestion:index - 1];
        [self loadQuestion:index + 1];
    } else {
        NSLog(@"attempt to navigate to invalid question index");
    }
}

- (NSUInteger)currentIndex
{
    return [_questionControllers indexOfObject:_currentQuestionController];
}

- (IBAction)showNextQuestion
{
    NSUInteger currentIndex = [self currentIndex];
    if (currentIndex < (_survey.questions.count - 1)) {
        [self showQuestionAtIndex:currentIndex + 1 animatingForward:YES];
    }
}

- (IBAction)showPreviousQuestion
{
    NSUInteger currentIndex = [self currentIndex];
    if (currentIndex > 0) {
        [self showQuestionAtIndex:currentIndex - 1 animatingForward:NO];
    }
}

- (IBAction)dismiss
{
    [_delegate surveyControllerWasDismissed:self withAnswers:[_answers allValues]];
}

- (void)questionController:(MPSurveyQuestionViewController *)controller didReceiveAnswerProperties:(NSDictionary *)properties
{
    NSMutableDictionary *answer = [NSMutableDictionary dictionaryWithDictionary:properties];
    answer[@"$collection_id"] = @(_survey.collectionID);
    answer[@"$question_id"] = @(controller.question.ID);
    answer[@"$question_type"] = controller.question.type;
    answer[@"$survey_id"] = @(_survey.ID);
    answer[@"$time"] = [NSDate date];

    _answers[@(controller.question.ID)] = answer;

    if ([self currentIndex] < ([_survey.questions count] - 1)) {
        [self showNextQuestion];
    } else {
        [self dismiss];
    }
}

@end
