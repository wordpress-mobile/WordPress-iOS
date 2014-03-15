/*
 *  PasscodeManager.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */


#import "PasscodeManager.h"
#import "FXKeychain.h"
#import <math.h>

static NSString * const PasscodeProtectionStatusKey = @"PasscodeProtectionEnabled";
static NSString * const PasscodeKey = @"PasscodeKey";
static NSString * const PasscodeInactivityDuration = @"PasscodeInactivityDuration";
static NSString * const PasscodeInactivityStarted = @"PasscodeInactivityStarted";
static NSString * const PasscodeInactivityEnded = @"PasscodeInactivityEnded";

@interface PasscodeManager ()

@property (nonatomic, strong) void (^setupCompletedBlock)(BOOL success);
@property (nonatomic, strong) void (^verificationCompletedBlock)(BOOL success);
@property (nonatomic, strong) PasscodeViewController *passcodeViewController;
@property (nonatomic, strong) UIViewController *presentingViewController;
@property (nonatomic, strong) UIView *coverView;

@end

@implementation PasscodeManager

+ (PasscodeManager *)sharedManager {
    static PasscodeManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}


#pragma mark -
#pragma mark - Subscriptions management

-(void) activatePasscodeProtection
{
    if([self isPasscodeProtectionOn]){
        [self subscribeToNotifications];
    }
}

-(void) deactivatePasscodeProtection
{
    [self disableSubscriptions];
}

-(void)subscribeToNotifications
{
    [self disableSubscriptions];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleNotification:)
                                                 name: UIApplicationWillResignActiveNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleNotification:)
                                                 name: UIApplicationDidBecomeActiveNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleNotification:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
}

-(void)disableSubscriptions
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification object:nil];
    
}

-(void)handleNotification:(NSNotification *)notification
{
    if(notification.name == UIApplicationWillResignActiveNotification){
        [self startTrackingInactivity];
    }
    if(notification.name == UIApplicationDidEnterBackgroundNotification){
        if([self shouldLock]){
            [self presentCoverView];
        }
    }
    if(notification.name == UIApplicationDidBecomeActiveNotification)
    {
        [self dismissCoverView];
        [self stopTrackingInactivity];
        if([self shouldLock]){
            [self verifyPasscodeWithPasscodeType:PasscodeTypeVerify withCompletion:nil];
        }
    }
}


#pragma mark -
#pragma mark - PasscodeViewControllerDelegate methods

-(void)passcodeSetupCancelled
{
    if(self.setupCompletedBlock){
        self.setupCompletedBlock(NO);
        self.setupCompletedBlock = nil;
    }
    
    if(self.verificationCompletedBlock){
        self.verificationCompletedBlock(NO);
        self.verificationCompletedBlock = nil;
    }
    [self dismissLockScreen];
}

-(void)didVerifyPasscode
{
    if(self.verificationCompletedBlock){
        self.verificationCompletedBlock(YES);
        self.verificationCompletedBlock = nil;
    }
    [self dismissLockScreen];
}

-(void)passcodeVerificationFailed
{
    if(self.verificationCompletedBlock){
        self.verificationCompletedBlock(NO);
        self.verificationCompletedBlock = nil;
    }
}

-(void)didSetupPasscode
{
    [self togglePasscodeProtection:YES];
    if(self.setupCompletedBlock){
        self.setupCompletedBlock(YES);
        self.setupCompletedBlock = nil;
    }
    [self dismissLockScreen];
}

#pragma mark -
#pragma mark - Workflow launchers

- (void) disablePasscodeProtectionWithCompletion:(void (^) (BOOL success)) completion
{
    [self verifyPasscodeWithPasscodeType:PasscodeTypeVerifyForSettingChange withCompletion:^(BOOL success) {
        if(success){
            [self togglePasscodeProtection:NO];
        }
        completion(success);
    }];
}


- (void)verifyPasscodeWithPasscodeType:(PasscodeType) passcodeType withCompletion:(void (^) (BOOL success)) completion
{
    self.verificationCompletedBlock = completion;
    [self presentLockScreenWithPasscodeType:passcodeType];
}

-(void)presentLockScreenWithPasscodeType:(PasscodeType) passcodeType
{
    [self dismissLockScreen];
    self.passcodeViewController = [[PasscodeViewController alloc]initWithPasscodeType:passcodeType withDelegate:self];
    self.presentingViewController = [self topViewController];
    
    [self.presentingViewController.view.window.layer addAnimation:[self transitionAnimation:kCATransitionFade] forKey:kCATransition];
    [self.presentingViewController presentViewController:self.passcodeViewController animated:NO completion:nil];
}

-(void)setupNewPasscodeWithCompletion:(void (^)(BOOL success)) completion
{
    [self setPasscodeInactivityDurationInMinutes:@0];
    self.setupCompletedBlock = completion;
    [self presentLockScreenWithPasscodeType:PasscodeTypeSetup];
    
}

- (void) changePasscodeWithCompletion:(void (^)(BOOL success)) completion
{
    [self setPasscodeInactivityDurationInMinutes:[self getPasscodeInactivityDurationInMinutes]];
    self.setupCompletedBlock = completion;
    [self presentLockScreenWithPasscodeType:PasscodeTypeChangePasscode];
}

#pragma mark -
#pragma mark - Helper methods

- (UIViewController *)topViewController{
    
    NSArray *windows = [UIApplication sharedApplication].windows;
    
    for(int i=windows.count-1; i >= 0; i--)
    {
        UIWindow *window = windows[i];
        if(window.windowLevel == UIWindowLevelNormal){
            return [self topViewController:window.rootViewController];
        }
        
    }
    return nil;
}

- (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }
    
    if ([rootViewController.presentedViewController isMemberOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }
    
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}

-(BOOL) shouldLock
{
    NSNumber *inactivityLimit = [self getPasscodeInactivityDurationInMinutes];
    NSDate *inactivityStarted = [self getInactivityStartTime];
    NSDate *inactivityEnded = [self getInactivityEndTime];
    
    NSTimeInterval difference = [inactivityEnded timeIntervalSinceDate:inactivityStarted];
    if(isnan(difference)){
        difference = 0;
    }
    NSInteger differenceInMinutes = difference / 60;
    
    if(differenceInMinutes < 0){ //Date/Time on device might be altered.
        differenceInMinutes = [inactivityLimit integerValue] + 1;
    }
    
    if([self isPasscodeProtectionOn] && ([inactivityLimit integerValue] <= differenceInMinutes))
    {
        return YES;
    }
    return NO;
}
-(NSDate *)getInactivityStartTime
{
    return [FXKeychain defaultKeychain][PasscodeInactivityStarted];
}
-(NSDate *)getInactivityEndTime
{
    return [FXKeychain defaultKeychain][PasscodeInactivityEnded];
}

-(void)startTrackingInactivity
{
    [FXKeychain defaultKeychain][PasscodeInactivityStarted] = [NSDate date];
}
-(void)stopTrackingInactivity
{
    [FXKeychain defaultKeychain][PasscodeInactivityEnded] = [NSDate date];
}

- (void)dismissLockScreen
{
    [self.passcodeViewController.view.window.layer addAnimation:[self transitionAnimation:kCATransitionFade] forKey:kCATransition];
    [self.passcodeViewController dismissViewControllerAnimated:NO completion:nil];
}

- (void) presentCoverView
{
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    self.coverView = [[UIView alloc]initWithFrame:window.bounds];
    PasscodeViewController *pvc = [PasscodeViewController new];
    
    if(!IS_IPAD){
        [self.coverView addSubview:pvc.view];
    } else {
        [self.coverView setBackgroundColor:self.backgroundColor];
    }
    
    self.coverView.hidden = NO;
    [UIApplication.sharedApplication.keyWindow addSubview:self.coverView];
}

- (void) dismissCoverView{
    self.coverView.hidden = YES;
    [self.coverView removeFromSuperview];
}

- (void) setPasscode:(NSString *)passcode
{
    [FXKeychain defaultKeychain][PasscodeKey] = passcode;
}

- (BOOL) isPasscodeCorrect:(NSString *)passcode
{
    bool result = [[FXKeychain defaultKeychain][PasscodeKey] isEqualToString:passcode];
    if(result)
    {
        return YES;
    }
    else{
        return NO;
    }
    
}

- (void) togglePasscodeProtection:(BOOL)isOn
{
    if(isOn)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:PasscodeProtectionStatusKey];
        [self activatePasscodeProtection];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:PasscodeProtectionStatusKey];
        [self deactivatePasscodeProtection];
        
    }
}

- (void) setPasscodeInactivityDurationInMinutes:(NSNumber *) minutes
{
    [FXKeychain defaultKeychain][PasscodeInactivityDuration] = minutes;
}

- (NSNumber *) getPasscodeInactivityDurationInMinutes
{
    return   [NSNumber numberWithInteger:[[FXKeychain defaultKeychain][PasscodeInactivityDuration] integerValue]];
}

- (BOOL) isPasscodeProtectionOn
{
    NSString *status = [[NSUserDefaults standardUserDefaults]stringForKey:PasscodeProtectionStatusKey];
    
    if(status)
    {
        if([status isEqual: @"YES"])
        {
            return YES;
        }
        else
        {
            return NO;
        }
    }
    else{
        return NO;
    }
    
    return NO;
}

-(CATransition *)transitionAnimation:(NSString *)transitionType
{
    CATransition* transition = [CATransition animation];
    transition.duration = 0.2;
    transition.type = transitionType;
    transition.subtype = kCATransitionFromBottom;
    return transition;
}

#pragma mark -
#pragma mark - Styling Getters

-(UIColor *)backgroundColor
{
    if(_backgroundColor){
        return _backgroundColor;
    }
    else{
        return [UIColor whiteColor];
    }
}

-(UIColor *)instructionsLabelColor
{
    if(_instructionsLabelColor){
        return _instructionsLabelColor;
    }
    else{
        return [UIColor blackColor];
    }
}
-(UIColor *)cancelOrDeleteButtonColor
{
    if(_cancelOrDeleteButtonColor){
        return _cancelOrDeleteButtonColor;
    }
    else{
        return [UIColor blackColor];
    }
}
-(UIColor *)passcodeViewFillColor
{
    if(_passcodeViewFillColor){
        return _passcodeViewFillColor;
    }
    else{
        return [UIColor blackColor];
    }
}
-(UIColor *)passcodeViewLineColor
{
    if(_passcodeViewLineColor){
        return _passcodeViewLineColor;
    }
    else{
        return [UIColor blackColor];
    }
}
-(UIColor *)errorLabelColor
{
    if(_errorLabelColor){
        return _errorLabelColor;
    }
    else{
        return [UIColor whiteColor];
    }
}
-(UIColor *)errorLabelBackgroundColor
{
    if(_errorLabelBackgroundColor){
        return _errorLabelBackgroundColor;
    }
    else{
        return [UIColor redColor];
    }
}


-(UIFont *)instructionsLabelFont{
    if(_instructionsLabelFont){
        return _instructionsLabelFont;
    }else{
        return [UIFont systemFontOfSize:15];
    }
}

-(UIFont *)cancelOrDeleteButtonFont{
    if(_cancelOrDeleteButtonFont){
        return _cancelOrDeleteButtonFont;
    }else{
        return [UIFont systemFontOfSize:15];
    }
}
-(UIFont *)errorLabelFont{
    if(_errorLabelFont){
        return _errorLabelFont;
    }else{
        return [UIFont systemFontOfSize:15];
    }
}
-(PasscodeButtonStyleProvider *)buttonStyleProvider{
    if(_buttonStyleProvider){
        return _buttonStyleProvider;
    }
    else{
        return [[PasscodeButtonStyleProvider alloc]init];
    }
}
-(UIImage *)backgroundImage{
    return _backgroundImage;
}

@end
