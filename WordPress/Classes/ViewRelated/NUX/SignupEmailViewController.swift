import UIKit

class SignupEmailViewController: NUXAbstractViewController {

    // MARK: - Properties

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var emailField: LoginTextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var nextButton: LoginButton!

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        configureView()
        setupNextButton()
    }

    private func setupNavBar() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                           target: self,
                                           action: #selector(handleCancelButtonTapped))
        navigationItem.leftBarButtonItem = cancelButton
        addWordPressLogoToNavController()
        _ = addHelpButtonToNavController()
    }

    private func configureView() {
        WPStyleGuide.configureColors(for: view, andTableView: nil)

        instructionLabel.text = NSLocalizedString("To create your new WordPress.com account, please enter your email address.", comment: "Text instructing the user to enter their email address.")

        emailField.placeholder = NSLocalizedString("Email address", comment: "Placeholder for a textfield. The user may enter their email address.")
        emailField.accessibilityIdentifier = "Email address"
    }

    private func setupNextButton() {
        nextButton.isEnabled = false
        let nextButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        nextButton?.setTitle(nextButtonTitle, for: UIControlState())
        nextButton?.setTitle(nextButtonTitle, for: .highlighted)
        nextButton?.accessibilityIdentifier = "Next Button"
    }

    // MARK: - Misc

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
