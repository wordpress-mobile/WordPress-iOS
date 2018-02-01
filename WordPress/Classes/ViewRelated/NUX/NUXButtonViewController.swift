import UIKit

@objc protocol NUXButtonViewControllerDelegate {
    func primaryButtonPressed()
    @objc optional func secondaryButtonPressed()
}

class NUXButtonViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet var shadowView: UIView?
    @IBOutlet var primaryButton: UIButton?
    @IBOutlet var secondaryButton: UIButton?

    open var delegate: NUXButtonViewControllerDelegate?

    private var primaryButtonTitle: String?
    private var secondaryButtonTitle: String?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        primaryButton?.setTitle(primaryButtonTitle, for: UIControlState())

        primaryButton?.accessibilityIdentifier = accessibilityIdentifier(for: primaryButtonTitle)

        secondaryButton?.setTitle(secondaryButtonTitle, for: UIControlState())
        secondaryButton?.accessibilityIdentifier = accessibilityIdentifier(for: secondaryButtonTitle)

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

    private func accessibilityIdentifier(for string: String?) -> String {
        let buttonId = NSLocalizedString("Button", comment: "Appended accessibility identifier for buttons.")
        return "\(string ?? "") \(buttonId)"
    }

    // MARK: - Button Handling

    @IBAction func primaryButtonPressed(_ sender: Any) {
        delegate?.primaryButtonPressed()
    }

    @IBAction func secondaryButtonPressed(_ sender: Any) {
        delegate?.secondaryButtonPressed?()
    }

}
