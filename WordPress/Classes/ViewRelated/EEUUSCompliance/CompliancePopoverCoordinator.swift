import UIKit

final class CompliancePopoverCoordinator {
    fileprivate enum Constants {
        static let hasSavedPrivacyBannerSettingsKey = "hasSavedPrivacyBannerSettings"
    }

    private let viewController: UIViewController
    private let complianceService = ComplianceLocationService()
    private let defaults: UserDefaults

    init(viewController: UIViewController, defaults: UserDefaults = UserDefaults.standard) {
        self.viewController = viewController
        self.defaults = defaults
    }

    func presentIfNeeded() {
        guard FeatureFlag.compliancePopover.enabled else {
            return
        }
        complianceService.getIPCountryCode { [weak self] result in
            switch result {
            case .success(let countryCode):
                DispatchQueue.main.async {
                    guard let self, self.shouldShowPrivacyBanner(countryCode: countryCode) else {
                        return
                    }
                    let complianceViewModel = CompliancePopoverViewModel()
                    let complianceViewController = CompliancePopoverViewController(viewModel: complianceViewModel)
                    let bottomSheetViewController = BottomSheetViewController(childViewController: complianceViewController, customHeaderSpacing: 0)
                    bottomSheetViewController.show(from: self.viewController)
                }
            case .failure(let error):
                ()
            }
        }
    }

    func shouldShowPrivacyBanner(countryCode: String) -> Bool {
        let isCountryInEU = Self.gdprCountryCodes.contains(countryCode)
        let hasSavedPrivacySettings = defaults.hasSavedPrivacyBannerSettings
        return isCountryInEU && !hasSavedPrivacySettings
    }
}

private extension CompliancePopoverCoordinator {
    static let gdprCountryCodes: Set<String> = [
        "AT", "AUT", // Austria
        "BE", "BEL", // Belgium
        "BG", "BGR", // Bulgaria
        "HR", "HRV", // Croatia
        "CY", "CYP", // Cyprus
        "CZ", "CZE", // Czech Republic
        "DK", "DNK", // Denmark
        "EE", "EST", // Estonia
        "FI", "FIN", // Finland
        "FR", "FRA", // France
        "DE", "DEU", // Germany
        "GR", "GRC", // Greece
        "HU", "HUN", // Hungary
        "IE", "IRL", // Ireland
        "IT", "ITA", // Italy
        "LV", "LVA", // Latvia
        "LT", "LTU", // Lithuania
        "LU", "LUX", // Luxembourg
        "MT", "MLT", // Malta
        "NL", "NLD", // Netherlands
        "NO", "NOR", // Norway
        "PL", "POL", // Poland
        "PT", "PRT", // Portugal
        "RO", "ROU", // Romania
        "SK", "SVK", // Slovakia
        "SI", "SVN", // Slovenia
        "ES", "ESP", // Spain
        "SE", "SWE", // Sweden
        "CH", "CHE", // Switzerland
        "IS",
        "LI",
        "GB",
        // *Although the UK has departed from the EU as of January 2021,
        // the GDPR was enacted before its withdrawal and is therefore considered a valid UK law.*
    ]
}

private extension UserDefaults {
    @objc dynamic var hasSavedPrivacyBannerSettings: Bool {
        bool(forKey: CompliancePopoverCoordinator.Constants.hasSavedPrivacyBannerSettingsKey)
    }
}
