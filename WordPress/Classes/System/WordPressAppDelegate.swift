import UIKit
import Reachability

@UIApplicationMain
class WordPressAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    @objc var logger: WPLogger!
    var analytics: WPAppAnalytics!
    var crashlytics: WPCrashlytics!
    var hockey: HockeyManager!
    @objc var internetReachability: Reachability!
    var authManager: WordPressAuthenticationManager!
    @objc var connectionAvailable: Bool = true

    private var shouldRestoreApplicationState = false

    @objc class var shared: WordPressAppDelegate? {
        return UIApplication.shared.delegate as? WordPressAppDelegate
    }

    func application(_ app: UIApplication, willFinishLaunching options: [UIApplication.LaunchOptionsKey : Any] = [:]) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)

        WordPressAppDelegate.fixKeychainAccess()

        configureWordPressAuthenticator()

        configureReachability()
        configureSelfHostedChallengeHandler()

        window?.makeKeyAndVisible()

        let solver = WPAuthTokenIssueSolver()
        let isFixingAuthTokenIssue = solver.fixAuthTokenIssueAndDo { [weak self] in
            self?.runStartupSequence(with: options)
        }

        shouldRestoreApplicationState = !isFixingAuthTokenIssue

        return true
    }

    @objc func runStartupSequence(with launchOptions: [UIApplication.LaunchOptionsKey: Any] = [:]) {

    }

    var runningInBackground: Bool {
        return UIApplication.shared.applicationState == .background
    }
}
