import UIKit

@objc protocol NUXButtonViewControllerDelegate {
    func primaryButtonPressed()
    @objc optional func secondaryButtonPressed()
}

class NUXButtonViewController: UIViewController {
    typealias CallBackType = () -> Void

    // MARK: - Properties

    @IBOutlet var shadowView: UIView?
    @IBOutlet var stackView: UIStackView?
    @IBOutlet var bottomButton: NUXButton?
    @IBOutlet var topButton: NUXButton?

    open var delegate: NUXButtonViewControllerDelegate?

    private var bottomButtonTitle: String?
    private var topButtonTitle: String?
    private var topCallback: CallBackType?
    private var bottomCallback: CallBackType?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        bottomButton?.setTitle(bottomButtonTitle, for: UIControlState())
        bottomButton?.accessibilityIdentifier = accessibilityIdentifier(for: bottomButtonTitle)

        topButton?.setTitle(topButtonTitle, for: UIControlState())
        topButton?.accessibilityIdentifier = accessibilityIdentifier(for: topButtonTitle)

        // Hide secondary button if title is not provided.
        topButton?.isHidden = (topButtonTitle ?? "").isEmpty
        bottomButton?.isHidden = (bottomButtonTitle ?? "").isEmpty
    }

    // MARK: public API

    /// Public method to set the button titles.
    ///
    /// - Parameters:
    ///   - primary: Title string for primary button. Required.
    ///   - secondary: Title string for secondary button. Optional.
    func setButtonTitles(primary: String, secondary: String? = nil) {
        bottomButtonTitle = primary
        topButtonTitle = secondary
    }

    func setupTopButton(title: String, isPrimary: Bool = false, onTap callback: @escaping CallBackType) {
        topButtonTitle = title
        topButton?.isPrimary = isPrimary
        topButton?.isHidden = false
        topCallback = callback
    }

    func setupButtomButton(title: String, isPrimary: Bool = false, onTap callback: @escaping CallBackType) {
        bottomButtonTitle = title
        bottomButton?.isPrimary = isPrimary
        bottomButton?.isHidden = false
        bottomCallback = callback
    }

    // MARK: - Helpers

    private func accessibilityIdentifier(for string: String?) -> String {
        let buttonId = NSLocalizedString("Button", comment: "Appended accessibility identifier for buttons.")
        return "\(string ?? "") \(buttonId)"
    }

    // MARK: - Button Handling

    @IBAction func primaryButtonPressed(_ sender: Any) {
        guard let callback = bottomCallback else {
            delegate?.primaryButtonPressed()
            return
        }
        callback()
    }

    @IBAction func secondaryButtonPressed(_ sender: Any) {
        guard let callback = topCallback else {
            delegate?.secondaryButtonPressed?()
            return
        }
        callback()
    }

}
