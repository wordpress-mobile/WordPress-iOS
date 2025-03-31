import UIKit
import WordPressUI
import WordPressKit

/// SiteAddressViewController: log in by Site Address.
///
final class SiteAddressViewController: LoginViewController {

    /// Private properties.
    ///
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?

    // Required for `NUXKeyboardResponder` but unused here.
    var verticalCenterConstraint: NSLayoutConstraint?

    private var rows = [Row]()
    private weak var siteURLField: UITextField?
    private var errorMessage: String?
    private var shouldChangeVoiceOverFocus: Bool = false

    /// A state variable that is `true` if network calls are currently happening and so the
    /// view should be showing a loading indicator.
    ///
    /// This should only be modified within `configureViewLoading(_ loading:)`.
    ///
    /// This state is mainly used in `configureSubmitButton()` to determine whether the button
    /// should show an activity indicator.
    private var viewIsLoading: Bool = false

    /// Whether the protocol method `troubleshootSite` should be triggered after site info is fetched.
    ///
    private let isSiteDiscovery: Bool
    private let configuration = WordPressAuthenticator.shared.configuration
    private lazy var viewModel: SiteAddressViewModel = {
        return SiteAddressViewModel(
            isSiteDiscovery: isSiteDiscovery,
            xmlrpcFacade: WordPressXMLRPCAPIFacade(),
            authenticationDelegate: authenticationDelegate,
            blogService: WordPressComBlogService(),
            loginFields: loginFields
        )
    }()

    init?(isSiteDiscovery: Bool, coder: NSCoder) {
        self.isSiteDiscovery = isSiteDiscovery
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        self.isSiteDiscovery = false
        super.init(coder: coder)
    }

    // MARK: - Actions
    @IBAction func handleContinueButtonTapped(_ sender: NUXButton) {
        tracker.track(click: .submit)

        validateForm()
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        removeGoogleWaitingView()
        configureNavBar()
        setupTable()
        localizePrimaryButton()
        registerTableViewCells()
        loadRows()
        configureSubmitButton()
        configureForAccessibility()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        siteURLField?.text = loginFields.siteAddress
        configureSubmitButton()

        // Nav bar could be hidden from the host app, so reshow it.
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isSiteDiscovery {
            tracker.set(flow: .siteDiscovery)
        } else {
            tracker.set(flow: .loginWithSiteAddress)
        }

        if isMovingToParent {
            tracker.track(step: .start)
        } else {
            tracker.set(step: .start)
        }

        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))
        configureViewForEditingIfNeeded()
    }

    // MARK: - Overrides

    /// Style individual ViewController backgrounds, for now.
    ///
    override func styleBackground() {
        guard let unifiedBackgroundColor = WordPressAuthenticator.shared.unifiedStyle?.viewControllerBackgroundColor else {
            super.styleBackground()
            return
        }

        view.backgroundColor = unifiedBackgroundColor
    }

    /// Style individual ViewController status bars.
    ///
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return WordPressAuthenticator.shared.unifiedStyle?.statusBarStyle ?? WordPressAuthenticator.shared.style.statusBarStyle
    }

    /// Configures the appearance and state of the submit button.
    ///
    /// Use this instead of the overridden `configureSubmitButton(animating:)` since this uses the
    /// _current_ `viewIsLoading` state.
    private func configureSubmitButton() {
        configureSubmitButton(animating: viewIsLoading)
    }

    /// Configures the appearance and state of the submit button.
    ///
    override func configureSubmitButton(animating: Bool) {
        // This matches the string in WPiOS UI tests.
        submitButton?.accessibilityIdentifier = "Site Address Next Button"

        submitButton?.showActivityIndicator(animating)

        submitButton?.isEnabled = (
            !animating && canSubmit()
        )
    }

    /// Sets up accessibility elements in the order which they should be read aloud
    /// and quiets repetitive elements.
    ///
    private func configureForAccessibility() {
        view.accessibilityElements = [
            siteURLField as Any,
            tableView as Any,
            submitButton as Any
        ]

        UIAccessibility.post(notification: .screenChanged, argument: siteURLField)

        if UIAccessibility.isVoiceOverRunning {
            // Remove the placeholder if VoiceOver is running, because it speaks the label
            // and the placeholder together. Since the placeholder matches the label, it's
            // like VoiceOver is reading the same thing twice.
            siteURLField?.placeholder = nil
        }
    }

    /// Sets the view's state to loading or not loading.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    override func configureViewLoading(_ loading: Bool) {
        viewIsLoading = loading

        siteURLField?.isEnabled = !loading

        configureSubmitButton()
        navigationItem.hidesBackButton = loading
    }

    /// Configure the view for an editing state. Should only be called from viewWillAppear
    /// as this method skips animating any change in height.
    ///
    @objc func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            siteURLField?.becomeFirstResponder()
        }
    }

    override func displayRemoteError(_ error: Error) {
        guard authenticationDelegate.shouldHandleError(error) else {
            super.displayRemoteError(error)
            return
        }

        authenticationDelegate.handleError(error) { customUI in
            self.navigationController?.pushViewController(customUI, animated: true)
        }
    }

    /// Reload the tableview and show errors, if any.
    ///
    override func displayError(message: String, moveVoiceOverFocus: Bool = false) {
        if errorMessage != message {
            if !message.isEmpty {
                tracker.track(failure: message)
            }

            errorMessage = message
            shouldChangeVoiceOverFocus = moveVoiceOverFocus
            loadRows()
            tableView.reloadData()
        }
    }
}

// MARK: - UITableViewDataSource
extension SiteAddressViewController: UITableViewDataSource {
    /// Returns the number of rows in a section.
    ///
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    /// Configure cells delegate method.
    ///
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - Keyboard Notifications
extension SiteAddressViewController: NUXKeyboardResponder {
    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }

    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }
}

// MARK: - TextField Delegate conformance
extension SiteAddressViewController: UITextFieldDelegate {

    /// Handle the keyboard `return` button action.
    ///
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if canSubmit() {
            validateForm()
            return true
        }

        return false
    }
}

// MARK: - Private methods
private extension SiteAddressViewController {

    // MARK: - Configuration

    func configureNavBar() {
        navigationItem.title = WordPressAuthenticator.shared.displayStrings.logInTitle
        styleNavigationBar(forUnified: true)
    }

    func setupTable() {
        defaultTableViewMargin = tableViewLeadingConstraint?.constant ?? 0
        setTableViewMargins(forWidth: view.frame.width)
    }

    // MARK: - Table Management

    /// Registers all of the available TableViewCells.
    ///
    func registerTableViewCells() {
        let cells = [
            TextLabelTableViewCell.reuseIdentifier: TextLabelTableViewCell.loadNib(),
            TextFieldTableViewCell.reuseIdentifier: TextFieldTableViewCell.loadNib(),
            TextLinkButtonTableViewCell.reuseIdentifier: TextLinkButtonTableViewCell.loadNib()
        ]

        for (reuseIdentifier, nib) in cells {
            tableView.register(nib, forCellReuseIdentifier: reuseIdentifier)
        }
    }

    /// Describes how the tableView rows should be rendered.
    ///
    func loadRows() {
        rows = [.instructions, .siteAddress]

        if let errorText = errorMessage, !errorText.isEmpty {
            rows.append(.errorMessage)
        }

        if WordPressAuthenticator.shared.configuration.displayHintButtons {
            rows.append(.findSiteAddress)
        }
    }

    /// Configure cells.
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TextLabelTableViewCell where row == .instructions:
            configureInstructionLabel(cell)
        case let cell as TextFieldTableViewCell:
            configureTextField(cell)
        case let cell as TextLinkButtonTableViewCell:
            configureTextLinkButton(cell)
        case let cell as TextLabelTableViewCell where row == .errorMessage:
            configureErrorLabel(cell)
        default:
            WPAuthenticatorLogError("Error: Unidentified tableViewCell type found.")
        }
    }

    /// Configure the instruction cell.
    ///
    func configureInstructionLabel(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: WordPressAuthenticator.shared.displayStrings.siteLoginInstructions, style: .body)
    }

    /// Configure the textfield cell.
    ///
    func configureTextField(_ cell: TextFieldTableViewCell) {
        cell.configure(withStyle: .url,
                       placeholder: WordPressAuthenticator.shared.displayStrings.siteAddressPlaceholder)

        // Save a reference to the first textField so it can becomeFirstResponder.
        siteURLField = cell.textField
        cell.textField.delegate = self
        cell.textField.text = loginFields.siteAddress
        cell.onChangeSelectionHandler = { [weak self] textfield in
            self?.loginFields.siteAddress = textfield.nonNilTrimmedText()
            self?.configureSubmitButton()
        }

        SigninEditingState.signinEditingStateActive = true
    }

    /// Configure the "Find your site address" cell.
    ///
    func configureTextLinkButton(_ cell: TextLinkButtonTableViewCell) {
        cell.configureButton(text: WordPressAuthenticator.shared.displayStrings.findSiteButtonTitle)
        cell.actionHandler = { [weak self] in
            guard let self else {
                return
            }

            self.tracker.track(click: .showHelp)

            let alert = FancyAlertViewController.siteAddressHelpController(
                loginFields: self.loginFields,
                sourceTag: self.sourceTag,
                moreHelpTapped: {
                    self.tracker.track(click: .helpFindingSiteAddress)
            },
                onDismiss: {
                    self.tracker.track(click: .dismiss)

                    // Since we're showing an alert on top of this VC, `viewDidAppear` will not be called
                    // once the alert is dismissed (which is where the step would be reset automagically),
                    // so we need to manually reset the step here.
                    self.tracker.set(step: .start)
            })
            alert.modalPresentationStyle = .custom
            alert.transitioningDelegate = self
            self.present(alert, animated: true, completion: { [weak self] in
                self?.tracker.track(step: .help)
            })
        }
    }

    /// Configure the error message cell.
    ///
    func configureErrorLabel(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: errorMessage, style: .error)
        if shouldChangeVoiceOverFocus {
            UIAccessibility.post(notification: .layoutChanged, argument: cell)
        }
    }

    /// Push a custom view controller, provided by a host app, to the navigation stack
    func pushCustomUI(_ customUI: UIViewController) {
        /// Assign the help button of the newly injected UI to the same help button we are currently displaying
        /// We are making a somewhat big assumption here: the chrome of the new UI we insert would look like the UI
        /// WPAuthenticator is already displaying. Which is risky, but also kind of makes sense, considering
        /// we are also pushing that injected UI to the current navigation controller.
        if WordPressAuthenticator.shared.delegate?.supportActionEnabled == true {
            customUI.navigationItem.rightBarButtonItems = self.navigationItem.rightBarButtonItems
        }

        self.navigationController?.pushViewController(customUI, animated: true)
    }

    // MARK: - Private Constants

    /// Rows listed in the order they were created.
    ///
    enum Row {
        case instructions
        case siteAddress
        case findSiteAddress
        case errorMessage

        var reuseIdentifier: String {
            switch self {
            case .instructions:
                return TextLabelTableViewCell.reuseIdentifier
            case .siteAddress:
                return TextFieldTableViewCell.reuseIdentifier
            case .findSiteAddress:
                return TextLinkButtonTableViewCell.reuseIdentifier
            case .errorMessage:
                return TextLabelTableViewCell.reuseIdentifier
            }
        }
    }
}

// MARK: - Instance Methods

private extension SiteAddressViewController {

    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    func validateForm() {
        view.endEditing(true)
        displayError(message: "")

        // We need to to this here because before this point we need the URL to be pre-validated
        // exactly as the user inputs it, and after this point we need the URL to be the base site URL.
        // This isn't really great, but it's the only sane solution I could come up with given the current
        // architecture of this pod.
        loginFields.siteAddress = WordPressAuthenticator.baseSiteURL(string: loginFields.siteAddress)

        configureViewLoading(true)

        guard let url = URL(string: loginFields.siteAddress) else {
            configureViewLoading(false)
            return displayError(message: Localization.invalidURL, moveVoiceOverFocus: true)
        }

        // Checks that the site exists
        checkSiteExistence(url: url) { [weak self] in
            guard let self else { return }
            // skips XMLRPC check for site discovery or site address login if needed
            if (self.isSiteDiscovery && self.configuration.skipXMLRPCCheckForSiteDiscovery) ||
                self.configuration.skipXMLRPCCheckForSiteAddressLogin {
                self.fetchSiteInfo()
                return
            }
            // Proceeds to check for the site's WordPress
            self.guessXMLRPCURL(for: url.absoluteString)
        }
    }

    func checkSiteExistence(url: URL, onCompletion: @escaping () -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0 // waits for 10 seconds
        let task = URLSession.shared.dataTask(with: request) { [weak self] _, _, error in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                if let error, (error as NSError).code != NSURLErrorAppTransportSecurityRequiresSecureConnection {
                    self.configureViewLoading(false)

                    if self.authenticationDelegate.shouldHandleError(error) {
                        self.authenticationDelegate.handleError(error) { customUI in
                            self.pushCustomUI(customUI)
                        }
                        return
                    }

                    var message: String?

                    // Use `URLError`'s error message (which usually contains more accurate description), if the
                    // error is SSL error.
                    if let urlError = error as? URLError, urlError.failureURLPeerTrust != nil {
                        message = urlError.localizedDescription
                    }

                    return self.displayError(message: message ?? Localization.nonExistentSiteError, moveVoiceOverFocus: true)
                }

                onCompletion()
            }
        }
        task.resume()
    }

    func guessXMLRPCURL(for siteAddress: String) {
        viewModel.guessXMLRPCURL(
            for: siteAddress,
            loading: { [weak self] isLoading in
                self?.configureViewLoading(isLoading)
            },
            completion: { [weak self] result -> Void in
                guard let self else { return }
                switch result {
                case .success:
                    // Let's try to grab site info in preparation for the next screen.
                    self.fetchSiteInfo()
                case .error(let error, let errorMessage):
                    if let message = errorMessage {
                        self.displayError(message: message, moveVoiceOverFocus: true)
                    } else {
                        self.displayError(error, sourceTag: self.sourceTag)
                    }
                case .troubleshootSite:
                    WordPressAuthenticator.shared.delegate?.troubleshootSite(nil, in: self.navigationController)
                case .customUI(let viewController):
                    self.pushCustomUI(viewController)
                }
            })
    }

    func fetchSiteInfo() {
        let baseSiteUrl = WordPressAuthenticator.baseSiteURL(string: loginFields.siteAddress)
        let service = WordPressComBlogService()

        let successBlock: (WordPressComSiteInfo) -> Void = { [weak self] siteInfo in
            guard let self else {
                return
            }
            self.configureViewLoading(false)
            if siteInfo.isWPCom && WordPressAuthenticator.shared.delegate?.allowWPComLogin == false {
                // Hey, you have to log out of your existing WP.com account before logging into another one.
                self.promptUserToLogoutBeforeConnectingWPComSite()
                return
            }
            self.presentNextControllerIfPossible(siteInfo: siteInfo)
        }

        service.fetchUnauthenticatedSiteInfoForAddress(for: baseSiteUrl, success: successBlock, failure: { [weak self] error in
            self?.configureViewLoading(false)
            guard let self else {
                return
            }

            if self.authenticationDelegate.shouldHandleError(error) {
                self.authenticationDelegate.handleError(error) { [weak self] customUI in
                    self?.navigationController?.pushViewController(customUI, animated: true)
                }
            } else {
                self.displayError(message: Localization.invalidURL)
            }
        })
    }

    func presentNextControllerIfPossible(siteInfo: WordPressComSiteInfo?) {

        // Ensure that we're using the verified URL before passing the `loginFields` to the next
        // view controller.
        //
        // In some scenarios, the text field change callback in `configureTextField()` gets executed
        // right after we validated and modified `loginFields.siteAddress` in `validateForm()`. And
        // this causes the value of `loginFields.siteAddress` to be reset to what the user entered.
        //
        // Using the user-entered `loginFields.siteAddress` causes problems when we try to log
        // the user in especially if they just use a domain. For example, validating their
        // self-hosted site credentials fails because the
        // `WordPressOrgXMLRPCValidator.guessXMLRPCURLForSite` expects a complete site URL.
        //
        // This routine fixes that problem. We'll use what we already validated from
        // `fetchSiteInfo()`.
        //
        if let verifiedSiteAddress = siteInfo?.url {
            loginFields.siteAddress = verifiedSiteAddress
        }

        guard isSiteDiscovery == false else {
            WordPressAuthenticator.shared.delegate?.troubleshootSite(siteInfo, in: navigationController)
            return
        }

        guard siteInfo?.isWPCom == false else {
            showGetStarted()
            return
        }

        WordPressAuthenticator.shared.delegate?.shouldPresentUsernamePasswordController(for: siteInfo, onCompletion: { (result) in
            switch result {
            case let .error(error):
                self.displayError(message: error.localizedDescription)
            case let .presentPasswordController(isSelfHosted):
                if isSelfHosted {
                    self.showSelfHostedUsernamePassword()
                    return
                }

                self.showWPUsernamePassword()
            case .presentEmailController:
                self.showGetStarted()
            case let .injectViewController(customUI):
                self.pushCustomUI(customUI)
            }
        })
    }

    func originalErrorOrError(error: NSError) -> NSError {
        guard let err = error.userInfo[XMLRPCOriginalErrorKey] as? NSError else {
            return error
        }

        return err
    }

    /// Here we will continue with the self-hosted flow.
    ///
    func showSelfHostedUsernamePassword() {
        configureViewLoading(false)
        guard let vc = SiteCredentialsViewController.instantiate(from: .siteAddress) else {
            WPAuthenticatorLogError("Failed to navigate from SiteAddressViewController to SiteCredentialsViewController")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }

    /// Break away from the self-hosted flow.
    /// Display a username / password login screen for WP.com sites.
    ///
    func showWPUsernamePassword() {
        configureViewLoading(false)

        guard let vc = LoginUsernamePasswordViewController.instantiate(from: .login) else {
            WPAuthenticatorLogError("Failed to navigate from SiteAddressViewController to LoginUsernamePasswordViewController")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }

    /// If the site is WordPressDotCom, redirect to WP login.
    ///
    func showGetStarted() {
        guard let vc = GetStartedViewController.instantiate(from: .getStarted) else {
            WPAuthenticatorLogError("Failed to navigate from SiteAddressViewController to GetStartedViewController")
            return
        }
        vc.source = .wpComSiteAddress

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }

    /// Whether the form can be submitted.
    ///
    func canSubmit() -> Bool {
        return loginFields.validateSiteForSignin()
    }

    @objc private func promptUserToLogoutBeforeConnectingWPComSite() {
        let acceptActionTitle = NSLocalizedString("OK", comment: "Alert dismissal title")
        let message = NSLocalizedString("Please log out before connecting to a different wordpress.com site", comment: "Message for alert to prompt user to logout before connecting to a different wordpress.com site.")
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addDefaultActionWithTitle(acceptActionTitle)
        present(alertController, animated: true)
    }
}

private extension SiteAddressViewController {
    enum Localization {
        static let invalidURL = NSLocalizedString(
            "Invalid URL. Please double-check and try again.",
            comment: "Error message shown when the input URL is invalid.")
        static let nonExistentSiteError = NSLocalizedString(
            "Cannot access the site at this address. Please double-check and try again.",
            comment: "Error message shown when the input URL does not point to an existing site.")
    }
}
