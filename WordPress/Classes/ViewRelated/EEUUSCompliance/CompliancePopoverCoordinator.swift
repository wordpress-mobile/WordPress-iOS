import UIKit

protocol CompliancePopoverCoordinatorProtocol: AnyObject {
    func presentIfNeeded()
    func navigateToSettings()
    func dismiss()
}

final class CompliancePopoverCoordinator: CompliancePopoverCoordinatorProtocol {

    // MARK: - Dependencies

    private let complianceService = ComplianceLocationService()
    private let defaults: UserDefaults

    // MARK: - Views

    private static var window: UIWindow?

    private let presentingViewController = UIViewController()

    // MARK: - Init

    init(defaults: UserDefaults = UserDefaults.standard) {
        self.defaults = defaults
    }

    func presentIfNeeded() {
        guard FeatureFlag.compliancePopover.enabled, !defaults.didShowCompliancePopup else {
            return
        }
        complianceService.getIPCountryCode { [weak self] result in
            guard let self, case .success(let countryCode) = result, self.shouldShowPrivacyBanner(countryCode: countryCode) else {
                return
            }
            DispatchQueue.main.async {
                self.presentPopover()
            }
        }
    }

    func navigateToSettings() {
        self.dismiss {
            RootViewCoordinator.sharedPresenter.navigateToPrivacySettings()
        }
    }

    func dismiss() {
        self.dismiss(completion: nil)
    }

    // MARK: - Helpers

    private func shouldShowPrivacyBanner(countryCode: String) -> Bool {
        let isCountryInEU = Self.gdprCountryCodes.contains(countryCode)
        return isCountryInEU && !defaults.didShowCompliancePopup
    }

    private func dismiss(completion: (() -> Void)? = nil) {
        self.presentingViewController.dismiss(animated: true) {
            self.removeWindow()
            completion?()
        }
    }

    private func removeWindow() {
        guard let window = Self.window else {
            return
        }
        window.isHidden = true
        window.resignKey()
        Self.window = nil
    }

    private func presentPopover() {
        self.removeWindow()

        let window = UIWindow()
        window.windowLevel = .alert
        window.backgroundColor = .clear
        window.rootViewController = presentingViewController
        window.makeKeyAndVisible()
        Self.window = window

        let complianceViewModel = CompliancePopoverViewModel(
            defaults: defaults,
            contextManager: ContextManager.shared
        )
        complianceViewModel.coordinator = self
        let complianceViewController = CompliancePopoverViewController(viewModel: complianceViewModel)
        let bottomSheetViewController = BottomSheetViewController(childViewController: complianceViewController, customHeaderSpacing: 0)

        bottomSheetViewController.show(from: presentingViewController)
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

extension UserDefaults {
    static let didShowCompliancePopupKey = "didShowCompliancePopup"

    var didShowCompliancePopup: Bool {
        get {
            bool(forKey: Self.didShowCompliancePopupKey)
        } set {
            set(newValue, forKey: Self.didShowCompliancePopupKey)
        }
    }
}
