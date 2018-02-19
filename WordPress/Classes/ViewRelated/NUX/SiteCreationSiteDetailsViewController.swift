import UIKit

class SiteCreationSiteDetailsViewController: NUXViewController, NUXKeyboardResponder {

    // MARK: - SigninKeyboardResponder Properties

    @IBOutlet weak var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet weak var verticalCenterConstraint: NSLayoutConstraint?

    // MARK: - Properties

    @IBOutlet weak var stepLabel: UILabel!
    @IBOutlet weak var stepDescriptionLabel1: UILabel!
    @IBOutlet weak var stepDescriptionLabel2: UILabel!
    @IBOutlet weak var siteTitleLabel: UILabel!
    @IBOutlet weak var taglineLabel: UILabel!
    @IBOutlet weak var siteTitleField: LoginTextField!
    @IBOutlet weak var taglineField: LoginTextField!
    @IBOutlet weak var tagDescriptionLabel: UILabel!
    @IBOutlet weak var nextButton: NUXButton!
    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .wpComCreateSiteDetails
        }
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        setLabelText()
        setupNextButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureViewForEditingIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let siteTitle = siteTitleField.text else {
            return
        }

        SiteCreationFields.sharedInstance.title = siteTitle
        SiteCreationFields.sharedInstance.tagline = taglineField.text

        let backButton = UIBarButtonItem()
        backButton.title = NSLocalizedString("Back", comment: "Back button title.")
        navigationItem.backBarButtonItem = backButton
    }

    /// Configure the view for an editing state. Should only be called from viewWillAppear
    /// as this method skips animating any change in height.
    ///
    private func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editiing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            siteTitleField.becomeFirstResponder()
        }
    }

    private func configureView() {
        setupHelpButtonIfNeeded()

        navigationItem.title = NSLocalizedString("Create New Site", comment: "Create New Site title.")
        WPStyleGuide.configureColors(for: view, andTableView: nil)
        nextButton.isEnabled = false
        siteTitleField.contentInsets = WPStyleGuide.edgeInsetForLoginTextFields()
        taglineField.contentInsets = WPStyleGuide.edgeInsetForLoginTextFields()
    }

    private func setLabelText() {
        stepLabel.text = NSLocalizedString("STEP 3 OF 4", comment: "Step for view.")
        stepDescriptionLabel1.text = NSLocalizedString("Tell us more about the site you're creating.", comment: "Shown during the site details step of the site creation flow.")
        stepDescriptionLabel2.text = NSLocalizedString("What's the title and tagline?", comment: "Prompts the user for Site details information.")

        siteTitleLabel.text = NSLocalizedString("Site Title", comment: "Label for Site Title field.")
        siteTitleField.placeholder = NSLocalizedString("Add title", comment: "Placeholder text for Site Title field.")
        siteTitleField.accessibilityIdentifier = "Site title"

        taglineLabel.text = NSLocalizedString("Site Tagline", comment: "Label for Site Tagline field.")
        taglineField.placeholder = NSLocalizedString("Optional tagline", comment: "Placeholder text for Site Tagline field.")
        taglineField.accessibilityIdentifier = "Site tagline"

        tagDescriptionLabel.text = NSLocalizedString("The tagline is a short line of text shown right below the title in most themes, and acts as site metadata on search engines.", comment: "Tagline description.")
    }

    private func setupNextButton() {
        let nextButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        nextButton?.setTitle(nextButtonTitle, for: UIControlState())
        nextButton?.setTitle(nextButtonTitle, for: .highlighted)
        nextButton?.accessibilityIdentifier = "Next Button"
    }

    // MARK: - Button Handling

    @IBAction func nextButtonPressed(_ sender: Any) {
        validateForm()
    }

    private func validateForm() {
        if siteTitleField.nonNilTrimmedText().isEmpty {
            displayErrorAlert(NSLocalizedString("Site Title must have a value.", comment: "Error shown when Site Title does not have a value."), sourceTag: sourceTag)
        }
        else {
            performSegue(withIdentifier: .showDomains, sender: self)
        }
    }

    private func toggleNextButton(_ textField: UITextField) {
        if textField == siteTitleField {
            nextButton.isEnabled = !textField.nonNilTrimmedText().isEmpty
        }
    }

    // MARK: - Keyboard Notifications

    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }

    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }

    // MARK: - Misc

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: - UITextFieldDelegate

extension SiteCreationSiteDetailsViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == siteTitleField {
            taglineField.becomeFirstResponder()
        } else if textField == taglineField {
            view.endEditing(true)
            validateForm()
        }

        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == siteTitleField {
            let updatedString = NSString(string: textField.text!).replacingCharacters(in: range, with: string)
            nextButton.isEnabled = !updatedString.trim().isEmpty
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        toggleNextButton(textField)
    }

    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        toggleNextButton(textField)
    }

}
