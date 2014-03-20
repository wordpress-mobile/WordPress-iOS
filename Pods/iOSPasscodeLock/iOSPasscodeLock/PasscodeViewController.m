/*
*  MainViewController.m
*
* Copyright (c) 2014 WordPress. All rights reserved.
*
* Licensed under GNU General Public License 2.0.
* Some rights reserved. See license.txt
*/

#import "PasscodeViewController.h"
#import "PasscodeCoordinator.h" 
#import "PasscodeCircularButton.h"
#import "PasscodeCircularView.h"

#ifndef IS_IPAD
#define IS_IPAD   ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
#endif

static CGFloat const TouchButtonSize = 65;
static CGFloat const TouchButtonSizeiPad = 80;
static CGFloat const PasscodeButtonPaddingHorizontal = 20;
static CGFloat const PasscodeButtonPaddingVertical = 10;
static CGFloat const PasscodeEntryViewSize = 14;
static CGFloat const LogoSize = 40;
static CGFloat const LogoSizeiPad = 50;

static NSInteger const PasscodeDigitCount = 4;


typedef enum PasscodeWorkflowStep : NSUInteger {
    WorkflowStepOne,
    WorkflowStepSetupPasscodeEnteredOnce,
    WorkflowStepSetupPasscodeEnteredTwice,
    WorkflowStepSetupPasscodesDidNotMatch,
    WorkflowStepChangePasscodeVerified,
    WorkflowStepChangePasscodeNotVerified,
} PasscodeWorkflowStep;

typedef enum PasscodeErrorType : NSUInteger {
    PasscodeErrorTypeIncorrectPasscode,
    PasscodeErrorTypePascodesDidNotMatch
} PasscodeErrorType;

@interface PasscodeViewController ()

@property (strong, nonatomic) UILabel *lblInstruction;
@property (strong, nonatomic) UIButton *btnCancelOrDelete;
@property (strong, nonatomic) NSString *passcodeFirstEntry;
@property (strong, nonatomic) NSString *passcodeEntered;
@property (strong, nonatomic) NSMutableArray *passcodeEntryViews;
@property (strong, nonatomic) UIView *passcodeEntryViewsContainerView;
@property (strong, nonatomic) UIImageView *backgroundImageView;
@property (strong, nonatomic) UIImageView *logoImageView;
@property (strong, nonatomic) NSMutableArray *passcodeButtons;
@property (assign) NSInteger numberOfDigitsEntered;
@property (assign) PasscodeType passcodeType;
@property (assign) PasscodeWorkflowStep currentWorkflowStep;
@property (assign) CGFloat passcodeButtonSize;

@end


@implementation PasscodeViewController

#pragma mark - 
#pragma mark - Lifecycle Methods

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self generateView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (id)initWithPasscodeType:(PasscodeType)type withDelegate:(id<PasscodeViewControllerDelegate>)delegate{
    self = [super init];
    if(self) {
        _currentWorkflowStep = WorkflowStepOne;
        _passcodeType = type;
        _delegate = delegate;
    }
    return self;
}

#pragma mark -
#pragma mark - Event Handlers

- (void)cancelOrDeleteBtnPressed:(id)sender {
    if(self.btnCancelOrDelete.tag == 1) {
        [self.delegate passcodeSetupCancelled];
    }
    else if(self.btnCancelOrDelete.tag == 2) {
        NSInteger currentPasscodeLength = self.passcodeEntered.length;
        PasscodeCircularView *pcv = self.passcodeEntryViews[currentPasscodeLength-1];
        [pcv clear];
        self.numberOfDigitsEntered--;
        self.passcodeEntered = [self.passcodeEntered substringToIndex:currentPasscodeLength-1];
        if(self.numberOfDigitsEntered == 0){
            self.btnCancelOrDelete.hidden = YES;
            [self enableCancelIfAllowed];
        }
    }
}

- (void) passcodeBtnPressed:(PasscodeCircularButton *)button {
    if(self.numberOfDigitsEntered < PasscodeDigitCount) {
        NSInteger tag = button.tag;
        NSString *tagStr = [[NSNumber numberWithInteger:tag] stringValue];
        self.passcodeEntered = [NSString stringWithFormat:@"%@%@", self.passcodeEntered, tagStr];
        PasscodeCircularView *pcv = self.passcodeEntryViews[self.numberOfDigitsEntered];
        [pcv fill];
        self.numberOfDigitsEntered++;
        
        if(self.numberOfDigitsEntered == 1) {
            [self enableDelete];
        }
        else if(self.numberOfDigitsEntered == PasscodeDigitCount) {
            [self performSelectorInBackground:@selector(evaluatePasscodeEntry) withObject:nil];
        }
    }
}

#pragma mark -
#pragma mark - Layout Methods

- (NSUInteger)supportedInterfaceOrientations {
    UIUserInterfaceIdiom interfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
    if (interfaceIdiom == UIUserInterfaceIdiomPad) return UIInterfaceOrientationMaskAll;
    if (interfaceIdiom == UIUserInterfaceIdiomPhone) return UIInterfaceOrientationMaskPortrait;
    
    return UIInterfaceOrientationMaskAll;
}
- (void)viewWillLayoutSubviews{
    [self buildLayout];
}

- (void)generateView {
    self.passcodeButtonSize = (IS_IPAD) ? TouchButtonSizeiPad : TouchButtonSize;

    [self applyBackgroundImageAndLogo];
    [self createButtons];
    [self createPasscodeEntryView];
    [self buildLayout];
    [self updateLayoutBasedOnWorkflowStep];
    [self.view setBackgroundColor:[PasscodeCoordinator sharedCoordinator].backgroundColor];
}
- (void)createButtons {
    self.passcodeButtons = [NSMutableArray new];
    CGRect initialFrame = CGRectMake(0, 0, self.passcodeButtonSize, self.passcodeButtonSize);
    
    PasscodeButtonStyleProvider *styleProvider = [PasscodeCoordinator sharedCoordinator].buttonStyleProvider;
    BOOL styleForAllButtonsExists = [styleProvider customStyleExistsForButtonType:PasscodeButtonTypeAll];
    
    for(int i = 0; i < 10; i++) {
        PasscodeButtonStyle *buttonStyle;
        
        if(!styleForAllButtonsExists) {
            buttonStyle = [styleProvider styleForButtonType:i];
        }
        else {
            buttonStyle = [styleProvider styleForButtonType:PasscodeButtonTypeAll];
        }
        
        NSString *passcodeNumberStr = [NSString stringWithFormat:@"%d",i];
        PasscodeCircularButton *passcodeButton = [[PasscodeCircularButton alloc]initWithNumber:passcodeNumberStr
                                                                                         frame:initialFrame
                                                                                         style:buttonStyle];
        
        [passcodeButton addTarget:self action:@selector(passcodeBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.passcodeButtons addObject:passcodeButton];

    }
    
    
    self.btnCancelOrDelete = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.btnCancelOrDelete.frame = initialFrame;
    [self.btnCancelOrDelete setTitleColor:[PasscodeCoordinator sharedCoordinator].cancelOrDeleteButtonColor forState:UIControlStateNormal];
    self.btnCancelOrDelete.hidden = YES;
    [self.btnCancelOrDelete setTitle:@"" forState:UIControlStateNormal];
    [self.btnCancelOrDelete addTarget:self action:@selector(cancelOrDeleteBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.btnCancelOrDelete.titleLabel.font = [PasscodeCoordinator sharedCoordinator].cancelOrDeleteButtonFont;
    
    self.lblInstruction = [[UILabel alloc]initWithFrame:CGRectZero];
    self.lblInstruction.textColor = [PasscodeCoordinator sharedCoordinator].instructionsLabelColor;
    self.lblInstruction.font = [PasscodeCoordinator sharedCoordinator].instructionsLabelFont;
}

- (void)buildLayout {
    CGFloat buttonRowWidth = (self.passcodeButtonSize * 3) + (PasscodeButtonPaddingHorizontal * 2);
    CGFloat firstButtonX = ([self returnWidth]/2) - (buttonRowWidth/2) + 0.5;
    CGFloat middleButtonX = firstButtonX + self.passcodeButtonSize + PasscodeButtonPaddingHorizontal;
    CGFloat lastButtonX = middleButtonX + self.passcodeButtonSize + PasscodeButtonPaddingHorizontal;
    CGFloat firstRowY = (IS_IPAD) ? ([self returnHeight]/2) - self.passcodeButtonSize * 2 : ([self returnHeight]/2) - self.passcodeButtonSize;
    CGFloat middleRowY = firstRowY + self.passcodeButtonSize + PasscodeButtonPaddingVertical;
    CGFloat lastRowY = middleRowY + self.passcodeButtonSize + PasscodeButtonPaddingVertical;
    CGFloat zeroRowY = lastRowY + self.passcodeButtonSize + PasscodeButtonPaddingVertical;
    
    NSValue *frameBtnOne = [NSValue valueWithCGRect:CGRectMake(firstButtonX, firstRowY, self.passcodeButtonSize, self.passcodeButtonSize)];
    NSValue *frameBtnTwo = [NSValue valueWithCGRect:CGRectMake(middleButtonX, firstRowY, self.passcodeButtonSize, self.passcodeButtonSize)];
    NSValue *frameBtnThree = [NSValue valueWithCGRect:CGRectMake(lastButtonX, firstRowY, self.passcodeButtonSize, self.passcodeButtonSize)];
    NSValue *frameBtnFour = [NSValue valueWithCGRect:CGRectMake(firstButtonX, middleRowY, self.passcodeButtonSize, self.passcodeButtonSize)];
    NSValue *frameBtnFive = [NSValue valueWithCGRect:CGRectMake(middleButtonX, middleRowY, self.passcodeButtonSize, self.passcodeButtonSize)];
    NSValue *frameBtnSix = [NSValue valueWithCGRect:CGRectMake(lastButtonX, middleRowY, self.passcodeButtonSize, self.passcodeButtonSize)];
    NSValue *frameBtnSeven = [NSValue valueWithCGRect:CGRectMake(firstButtonX, lastRowY, self.passcodeButtonSize, self.passcodeButtonSize)];
    NSValue *frameBtnEight = [NSValue valueWithCGRect:CGRectMake(middleButtonX, lastRowY, self.passcodeButtonSize, self.passcodeButtonSize)];
    NSValue *frameBtnNine = [NSValue valueWithCGRect:CGRectMake(lastButtonX, lastRowY, self.passcodeButtonSize, self.passcodeButtonSize)];
    NSValue *frameBtnZero = [NSValue valueWithCGRect:CGRectMake(middleButtonX, zeroRowY, self.passcodeButtonSize, self.passcodeButtonSize)];
   
    CGRect frameBtnCancel = CGRectMake(lastButtonX, zeroRowY, self.passcodeButtonSize, self.passcodeButtonSize);
    CGRect frameLblInstruction = CGRectMake(0, 0, 300, 20);
    CGRect frameLogo = (IS_IPAD) ? CGRectMake(0, 0, LogoSizeiPad, LogoSizeiPad) : CGRectMake(0, 0, LogoSize, LogoSize);
    CGRect frameBackgroundImageView = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, [self returnWidth], [self returnHeight]);
    
    NSArray *buttonFrames = @[frameBtnZero, frameBtnOne, frameBtnTwo, frameBtnThree, frameBtnFour, frameBtnFive, frameBtnSix, frameBtnSeven, frameBtnEight, frameBtnNine];
    
    for(int i = 0; i < 10; i++) {
        PasscodeCircularButton *passcodeButton = self.passcodeButtons[i];
        passcodeButton.frame = [buttonFrames[i] CGRectValue];
        [self.view addSubview:passcodeButton];
    }

    self.backgroundImageView.frame = frameBackgroundImageView;
    self.btnCancelOrDelete.frame = frameBtnCancel;
    self.lblInstruction.textAlignment = NSTextAlignmentCenter;
    self.lblInstruction.frame = frameLblInstruction;
    self.lblInstruction.center = CGPointMake([self returnWidth]/2, firstRowY - (PasscodeButtonPaddingVertical * 7));
    self.logoImageView.frame = frameLogo;
    self.logoImageView.center = (IS_IPAD) ? CGPointMake([self returnWidth]/2, firstRowY - (PasscodeButtonPaddingVertical) * 13) : CGPointMake([self returnWidth]/2, firstRowY - (PasscodeButtonPaddingVertical) * 12);
   
    [self.view addSubview:self.btnCancelOrDelete];
    [self.view addSubview:self.lblInstruction];
    
    CGFloat passcodeEntryViewsY = firstRowY - PasscodeButtonPaddingVertical * 4;
    CGFloat passcodeEntryViewWidth = (PasscodeDigitCount * PasscodeEntryViewSize) + ((PasscodeDigitCount - 1) * PasscodeButtonPaddingHorizontal);
    CGFloat passcodeEntryViewsX = ([self returnWidth] - passcodeEntryViewWidth) / 2;
    CGFloat insideContainerX = 0;
    CGRect framePasscodeEntryViewsContainerView = CGRectMake(passcodeEntryViewsX, passcodeEntryViewsY, passcodeEntryViewWidth, PasscodeEntryViewSize);
    
    self.passcodeEntryViewsContainerView = [[UIView alloc]initWithFrame:framePasscodeEntryViewsContainerView];
    for (PasscodeCircularView *circularView in self.passcodeEntryViews) {
        CGRect frame = CGRectMake(insideContainerX, 0, PasscodeEntryViewSize, PasscodeEntryViewSize);
        circularView.frame = frame;
        insideContainerX = insideContainerX + PasscodeEntryViewSize + PasscodeButtonPaddingHorizontal;
        [self.passcodeEntryViewsContainerView addSubview:circularView];
    }
    [self.view addSubview:self.passcodeEntryViewsContainerView];
 }

- (void)updateLayoutBasedOnWorkflowStep {
    self.btnCancelOrDelete.hidden = YES;
    
    if(self.passcodeType == PasscodeTypeSetup) {
        if(self.currentWorkflowStep == WorkflowStepOne)
        {
            self.lblInstruction.text = NSLocalizedString(@"Enter your new Passcode", nil);
        }
        else if(self.currentWorkflowStep == WorkflowStepSetupPasscodeEnteredOnce)
        {
            self.lblInstruction.text = NSLocalizedString(@"Re-enter your new Passcode", nil);
        }
        else if(self.currentWorkflowStep == WorkflowStepSetupPasscodesDidNotMatch)
        {
            self.lblInstruction.text = NSLocalizedString(@"Enter your new Passcode", nil);

            self.currentWorkflowStep = WorkflowStepOne;
        }
    }
    else if(self.passcodeType == PasscodeTypeVerify || self.passcodeType == PasscodeTypeVerifyForSettingChange) {
        self.lblInstruction.text = NSLocalizedString(@"Enter Passcode", nil);;
        if(self.passcodeType == PasscodeTypeVerifyForSettingChange){
        }
    }
    else if(self.passcodeType == PasscodeTypeChangePasscode) {
        if(self.currentWorkflowStep == WorkflowStepOne){
            self.lblInstruction.text = NSLocalizedString(@"Enter your old Passcode", nil);
        }
    }
    [self enableCancelIfAllowed];
    [self resetPasscodeEntryView];
}

#pragma mark - 
#pragma mark - UIView Handlers

-(void)enableDelete {
    if(!self.btnCancelOrDelete.tag != 2) {
        self.btnCancelOrDelete.tag = 2;
        [self.btnCancelOrDelete setTitle:NSLocalizedString(@"Delete",nil) forState:UIControlStateNormal];
    }
    if(self.btnCancelOrDelete.hidden) {
        self.btnCancelOrDelete.hidden = NO;
    }
}

- (void)enableCancelIfAllowed {
    if(self.passcodeType == PasscodeTypeChangePasscode || self.passcodeType == PasscodeTypeSetup || self.passcodeType == PasscodeTypeVerifyForSettingChange) {
        [self.btnCancelOrDelete setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
        self.btnCancelOrDelete.tag = 1;
        self.btnCancelOrDelete.hidden = NO;
    }
}
- (void) createPasscodeEntryView {
    self.passcodeEntryViews = [NSMutableArray new];
    self.passcodeEntered = @"";
    self.numberOfDigitsEntered = 0;
    UIColor *lineColor = [PasscodeCoordinator sharedCoordinator].passcodeViewLineColor;
    UIColor *fillColor = [PasscodeCoordinator sharedCoordinator].passcodeViewFillColor;
    CGRect frame = CGRectMake(0, 0, PasscodeEntryViewSize, PasscodeEntryViewSize);
    
    for (int i=0; i < PasscodeDigitCount; i++) {
        PasscodeCircularView *pcv = [[PasscodeCircularView alloc]initWithFrame:frame
                                                                     lineColor:lineColor
                                                                     fillColor:fillColor];
        [self.passcodeEntryViews addObject:pcv];
    }
}

- (void)resetPasscodeEntryView {
    for(PasscodeCircularView *pcv in self.passcodeEntryViews) {
        [pcv clear];
    }
    self.passcodeEntered = @"";
    self.numberOfDigitsEntered = 0;
}

- (void)performShake:(UIView *)view {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
	[animation setDuration:0.75];
	NSMutableArray *instructions = [NSMutableArray new];
	int loopCount = 4;
    CGFloat offSet = 30;
	
    while(offSet > 0.01) {
		[instructions addObject:[NSValue valueWithCGPoint:CGPointMake(view.center.x - offSet, view.center.y)]];
        offSet = offSet * 0.70;
		[instructions addObject:[NSValue valueWithCGPoint:CGPointMake(view.center.x + offSet, view.center.y)]];
        offSet = offSet * 0.70;
		loopCount--;
		if(loopCount <= 0) {
			break;
		}
	}
	animation.values = instructions;
	[view.layer addAnimation:animation forKey:@"position"];
}

- (void)applyBackgroundImageAndLogo {
    if([PasscodeCoordinator sharedCoordinator].backgroundImage) {
        self.backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self.backgroundImageView setImage:[PasscodeCoordinator sharedCoordinator].backgroundImage];
        [self.view addSubview:self.backgroundImageView];
    }
    if([PasscodeCoordinator sharedCoordinator].logo) {
        self.logoImageView = [[UIImageView alloc]initWithFrame:CGRectZero];
        [self.logoImageView setImage:[PasscodeCoordinator sharedCoordinator].logo];
        [self.view addSubview:self.logoImageView];
    }
}
#pragma mark -
#pragma mark - Helper methods

- (CGFloat)returnWidth {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    return (UIInterfaceOrientationIsLandscape(orientation)) ? self.view.frame.size.height : self.view.frame.size.width;
}

- (CGFloat)returnHeight {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    return (UIInterfaceOrientationIsLandscape(orientation)) ? self.view.frame.size.width : self.view.frame.size.height;
}

- (void)evaluatePasscodeEntry {
    [NSThread sleepForTimeInterval:0.1];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.passcodeType == PasscodeTypeSetup){
            if(self.currentWorkflowStep == WorkflowStepOne){
                self.currentWorkflowStep = WorkflowStepSetupPasscodeEnteredOnce;
                self.passcodeFirstEntry = self.passcodeEntered;
                [self updateLayoutBasedOnWorkflowStep];
            }
            else if(self.currentWorkflowStep == WorkflowStepSetupPasscodeEnteredOnce)
            {
                if([self.passcodeFirstEntry isEqualToString:self.passcodeEntered])
                {
                    [[PasscodeCoordinator sharedCoordinator] setPasscode:self.passcodeEntered];
                    [self.delegate didSetupPasscode];
                }
                else
                {
                    self.currentWorkflowStep = WorkflowStepSetupPasscodesDidNotMatch;
                    [self performErrorWithErrorType:PasscodeErrorTypePascodesDidNotMatch];
                    [self updateLayoutBasedOnWorkflowStep];
                }
            }
        }
        else if(self.passcodeType == PasscodeTypeVerify || self.passcodeType == PasscodeTypeVerifyForSettingChange){
            if([[PasscodeCoordinator sharedCoordinator] isPasscodeCorrect:self.passcodeEntered]){
                [self.delegate didVerifyPasscode];
            }
            else{
                [self performErrorWithErrorType:PasscodeErrorTypeIncorrectPasscode];
                self.currentWorkflowStep = WorkflowStepOne;
                [self updateLayoutBasedOnWorkflowStep];
            }
        }
        else if(self.passcodeType == PasscodeTypeChangePasscode)
        {
            if([[PasscodeCoordinator sharedCoordinator] isPasscodeCorrect:self.passcodeEntered]){
                self.passcodeType = PasscodeTypeSetup;
                self.currentWorkflowStep = WorkflowStepOne;
                [self updateLayoutBasedOnWorkflowStep];
            }
            else{
                [self performErrorWithErrorType:PasscodeErrorTypeIncorrectPasscode];
                self.currentWorkflowStep = WorkflowStepOne;
                [self updateLayoutBasedOnWorkflowStep];
            }
            
        }
    });
}

- (void)performErrorWithErrorType:(PasscodeErrorType) errorType {
    [self performShake:self.passcodeEntryViewsContainerView];
}

- (void)setDelegate:(id)newDelegate {
    self.delegate = newDelegate;
}

@end
