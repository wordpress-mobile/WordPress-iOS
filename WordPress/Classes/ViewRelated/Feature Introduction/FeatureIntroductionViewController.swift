import UIKit

// TODO: add description

class FeatureIntroductionViewController: UIViewController, StoryboardLoadable {

    // MARK: - StoryboardLoadable Protocol

    static var defaultStoryboardName = defaultControllerID

    // MARK: - Properties

    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var closeButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var buttonSeparator: UIView!
    @IBOutlet private weak var buttonSeparatorHeightConstraint: NSLayoutConstraint!


    // MARK: - Init

    class func controller() -> FeatureIntroductionViewController {
        return loadFromStoryboard()
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
    }

}

private extension FeatureIntroductionViewController {

    func configureView() {
        view.backgroundColor = .basicBackground

        closeButton.tintColor = .secondaryLabel
        closeButton.backgroundColor = .quaternarySystemFill
        closeButton.layer.cornerRadius = closeButtonWidthConstraint.constant * 0.5

        buttonSeparator.backgroundColor = .divider
        buttonSeparatorHeightConstraint.constant = .hairlineBorderWidth
    }

    @IBAction func closeButtonTapped() {
        dismiss(animated: true)
    }

}
