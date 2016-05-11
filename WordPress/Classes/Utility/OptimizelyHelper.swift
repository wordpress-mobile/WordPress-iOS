import Foundation
import Optimizely


// MARK: - Define live variables used in Optimizely experiments.
internal var optimizelyEnableNewSigninFlowKey: OptimizelyVariableKey = OptimizelyVariableKey.optimizelyKeyWithKey("EnableNewSigninFlow", defaultBOOL: false)


/// A helper class for interacting with the Optimizely SDK
///
@objc class OptimizelyHelper: NSObject
{

    /// Shared instance used for notification observer
    static let sharedInstance = OptimizelyHelper()
    static let OptimizelyLoggedInEventName = "logged_in"
    let ExperimentDescriptionKey = "experiment_description"
    let VariationDescriptioinKey = "variation_description"
    let AnalyticsProperyABTestNameKey = "abtest_name"
    let AnalyticsPropertyABTestVariationKey = "abtest_variation"


    /// Activate Optimizely. Call this once when the application finishes launching.
    ///
    /// - Parameters:
    ///     - launchOptions: The launchOptions dictionary from the app delegate.
    ///
    class func setupOptimizelyWithLaunchOptions(launchOptions: [NSObject: AnyObject]) {
        Optimizely.disableSwizzle() // Disable's the Optimizely visual editor.
        preregisterOptimizelyKeys()
        Optimizely.startOptimizelyWithAPIToken(ApiCredentials.optimizelyAPIKey(), launchOptions: launchOptions)
        Optimizely.refreshExperiments()

        NSNotificationCenter.defaultCenter().addObserver(self.sharedInstance, selector: #selector(self.optimizelyExperimentVisitedHandler), name: OptimizelyExperimentVisitedNotification, object: nil)
    }


    /// Preregister any live variables.
    ///
    class func preregisterOptimizelyKeys() {
        Optimizely.preregisterVariableKey(optimizelyEnableNewSigninFlowKey)
    }


    /// Returns the value of the EnableNewSigninFlow live variable
    ///
    /// - Returns: true if the new signin flow should be used. False otherwise.
    ///
    class func useNewSigninFlow() -> Bool {
        return Optimizely.boolForKey(optimizelyEnableNewSigninFlowKey)
    }


    /// Bumps the custom goal for logged in in the Sign in A/B test
    /// This can be removed when the test is complete.
    ///
    class func trackLoggedIn() {
        Optimizely.trackEvent(OptimizelyLoggedInEventName)
    }


    /// Handles the experiment visited notification. The userInfo dictionary
    /// should contain the following keys and values:
    ///
    /// "experiment_description" = "New Signin Flow";
    /// "experiment_id" = 5694410124;
    /// "variation_description" = Original;
    /// "variation_id" = 5690940129;
    ///
    func optimizelyExperimentVisitedHandler(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            experimentDescription = userInfo[ExperimentDescriptionKey],
            variationDescription = userInfo[VariationDescriptioinKey] else {
                return
        }

        let properties = [
            AnalyticsProperyABTestNameKey: experimentDescription,
            AnalyticsPropertyABTestVariationKey: variationDescription
        ]
        WPAppAnalytics.track(.ABTestStart, withProperties: properties)
    }

}
