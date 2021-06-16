import UITestsFoundation

// These are fake credentials used for the mocked UI tests
struct WPUITestCredentials {
    static let testWPcomUserEmail: String = "e2eflowtestingmobile@example.com"
    static let testWPcomUsername: String = "e2eflowtestingmobile"
    static let testWPcomPassword: String = "mocked_password"
    static let testWPcomSiteAddress: String =  "tricountyrealestate.wordpress.com"
    static let testWPcomSitePrimaryAddress: String =  "tricountyrealestate.wordpress.com"
    static let selfHostedUsername: String = "e2eflowtestingmobile"
    static let selfHostedPassword: String = "mocked_password"
    static let selfHostedSiteAddress: String = "\(WireMock.URL().absoluteString)"
    static let signupEmail: String = "e2eflowsignuptestingmobile@example.com"
    static let signupUsername: String = "e2eflowsignuptestingmobile"
    static let signupDisplayName: String = "Eeflowsignuptestingmobile"
    static let signupPassword: String = "mocked_password"
}
