import UIKit

@objc protocol SiteCreationButtonViewControllerDelegate {
    func primaryButtonPressed()
    @objc optional func secondaryButtonPressed()
}

class SiteCreationButtonViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet var shadowView: UIView?
    @IBOutlet var primaryButton: UIButton?
    @IBOutlet var secondaryButton: UIButton?

    open var delegate: SiteCreationButtonViewControllerDelegate?

    private var primaryButtonTitle: String?
    private var secondaryButtonTitle: String?

    // MARK: - View

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        primaryButton?.setTitle(primaryButtonTitle, for: UIControlState())
        primaryButton?.accessibilityIdentifier = accessibilityIdentifierForString(primaryButtonTitle)

        secondaryButton?.setTitle(secondaryButtonTitle, for: UIControlState())
        secondaryButton?.accessibilityIdentifier = accessibilityIdentifierForString(secondaryButtonTitle)

        // Hide secondary button if title is not provided.
        secondaryButton?.isHidden = (secondaryButtonTitle ?? "").isEmpty
    }


    /// Public method to set the button titles.
    ///
    /// - Parameters:
    ///   - primary: Title string for primary button. Required.
    ///   - secondary: Title string for secondary button. Optional.
    func setButtonTitles(primary: String, secondary: String? = nil) {
        primaryButtonTitle = primary
        secondaryButtonTitle = secondary
    }

    // MARK: - Helpers

    private func accessibilityIdentifierForString(_ string: String?) -> String {
        return "\(string ?? "") Button"
    }

    // MARK: - Button Handling

    @IBAction func primaryButtonPressed(_ sender: Any) {
        delegate?.primaryButtonPressed()
    }

    @IBAction func secondaryButtonPressed(_ sender: Any) {
        delegate?.secondaryButtonPressed?()
    }

}
