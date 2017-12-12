import UIKit

class SiteDetailsViewController: UIViewController, LoginWithLogoAndHelpViewController {

    // MARK: - Properties

    @IBOutlet weak var stepLabel: UILabel!
    @IBOutlet weak var stepDescrLabel1: UILabel!
    @IBOutlet weak var stepDescrLabel2: UILabel!
    @IBOutlet weak var siteTitleField: LoginTextField!
    @IBOutlet weak var taglineField: LoginTextField!
    @IBOutlet weak var tagDescrLabel: UILabel!
    @IBOutlet weak var nextButton: LoginButton!

    private var helpBadge: WPNUXHelpBadgeLabel!
    private var helpButton: UIButton!

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        setLabelText()
        setupBackgroundTapGestureRecognizer()
    }

    private func configureView() {
        navigationItem.title = NSLocalizedString("Create New Site", comment: "Create New Site title.")
        let (helpButtonResult, helpBadgeResult) = addHelpButtonToNavController()
        helpButton = helpButtonResult
        helpBadge = helpBadgeResult
        WPStyleGuide.configureColors(for: view, andTableView: nil)
        tagDescrLabel.textColor = WPStyleGuide.greyDarken20()
        nextButton.isEnabled = false
        siteTitleField.becomeFirstResponder()
        siteTitleField.textInsets.left = 20
        taglineField.textInsets.left = 20
    }

    private func setLabelText() {
        stepLabel.text = NSLocalizedString("STEP 3 OF 4", comment: "Step for view.")
        stepDescrLabel1.text = NSLocalizedString("Tell us more about the site you're creating.", comment: "Shown during the site details step of the site creation flow.")
        stepDescrLabel2.text = NSLocalizedString("What's the title and tagline?", comment: "Prompts the user for Site details information.")
        siteTitleField.placeholder = NSLocalizedString("Add title", comment: "Site title placeholder.")
        taglineField.placeholder = NSLocalizedString("Optional tagline", comment: "Site tagline placeholder.")
        tagDescrLabel.text = NSLocalizedString("The tagline is a short line of text shown right below the title in most themes, and acts as site metadata on search engines.", comment: "Tagline description.")
        nextButton.titleLabel?.text = NSLocalizedString("Next", comment: "Next button title.")
    }

    // MARK: - TapGestureRecognizer

    private func setupBackgroundTapGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SiteDetailsViewController.handleBackgroundTapGesture(_:)))
        view.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc private func handleBackgroundTapGesture(_ tgr: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    // MARK: - LoginWithLogoAndHelpViewController

    func handleHelpButtonTapped(_ sender: AnyObject) {
        displaySupportViewController(sourceTag: .wpComCreateSiteDetails)
    }

    func handleHelpshiftUnreadCountUpdated(_ notification: Foundation.Notification) {
        let count = HelpshiftUtils.unreadNotificationCount()
        helpBadge.text = "\(count)"
        helpBadge.isHidden = (count == 0)
    }

    // MARK: - Button Handling

    @IBAction func nextButtonPressed(_ sender: Any) {
        validateForm()
    }

    private func validateForm() {
        if !stringHasValue(siteTitleField.text) {
            showSiteTitleError()
        }
        else {
            let message = "Title: '\(siteTitleField.text!)'\nTagline: '\(taglineField.text ?? "")'\nThis is a work in progress. If you need to create a site, disable the siteCreation feature flag."
            let alertController = UIAlertController(title: nil,
                                                    message: message,
                                                    preferredStyle: .alert)
            alertController.addDefaultActionWithTitle("OK")
            self.present(alertController, animated: true, completion: nil)
        }
    }

    private func toggleNextButton(_ textField: UITextField) {
        if textField == siteTitleField {
            nextButton.isEnabled = stringHasValue(textField.text)
        }
    }

    private func showSiteTitleError() {
        let overlayView = WPWalkthroughOverlayView(frame: view.bounds)
        overlayView.overlayTitle = NSLocalizedString("Error", comment: "Title of Error alert.")
        overlayView.overlayDescription = NSLocalizedString("Site Title must have a value.", comment: "Error shown when Site Title does not have a value.")
        overlayView.dismissCompletionBlock = { overlayView in
            overlayView?.dismiss()
        }
        view.addSubview(overlayView)
    }

    // MARK: - Helpers

    private func stringHasValue(_ textString: String?) -> Bool {

        guard let textString = textString else {
            return false
        }

        return textString.trim().count > 0
    }

    // MARK: - Misc

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: - UITextFieldDelegate

extension SiteDetailsViewController: UITextFieldDelegate {

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
        let updatedString = NSString(string: textField.text!).replacingCharacters(in: range, with: string)
        nextButton.isEnabled = stringHasValue(updatedString)
        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if textField == siteTitleField {
            nextButton.isEnabled = false
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
