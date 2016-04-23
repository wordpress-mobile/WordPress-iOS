import Foundation
import Optimizely


// MARK: - Define live variables used in Optimizely experiments.
internal var optimizelyEnableNewSigninFlowKey: OptimizelyVariableKey = OptimizelyVariableKey.optimizelyKeyWithKey("EnableNewSigninFlow", defaultBOOL: false)


/// A helper class for interacting with the Optimizely SDK
///
@objc class OptimizelyHelper: NSObject
{

    /// Activate Optimizely. Call this once when the application finishes launching.
    ///
    /// - Parameters:
    ///     - launchOptions: The launchOptions dictionary from the app delegate.
    ///
    class func setupOptimizelyWithLaunchOptions(launchOptions: [NSObject: AnyObject]) {
        Optimizely.sharedInstance().verboseLogging = true
        preregisterOptimizelyKeys()
        Optimizely.startOptimizelyWithAPIToken(WordPressComApiCredentials.optimizelyAPIKey(), launchOptions: launchOptions)
        Optimizely.refreshExperiments()
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
        Optimizely.trackEvent("logged_in")
    }

}
