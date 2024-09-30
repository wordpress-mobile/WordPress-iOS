import UIKit

/// Methods to access the Me Scene and sub levels
extension RootViewPresenter {
    /// access to sub levels
    func navigateToAccountSettings() {
        showMeScreen {
            $0.navigateToAccountSettings()
        }
    }

    func navigateToAllDomains() {
        showMeScreen {
            $0.navigateToAllDomains()
        }
    }

    func navigateToAppSettings() {
        showMeScreen() {
            $0.navigateToAppSettings()
        }
    }

    func navigateToSupport() {
        showMeScreen {
            $0.navigateToHelpAndSupport()
        }
    }
}
