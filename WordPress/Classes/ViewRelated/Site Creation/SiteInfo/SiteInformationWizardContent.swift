import UIKit
import WordPressAuthenticator

typealias SIteInformationCompletion = (SiteInformation) -> Void

final class SiteInformationWizardContent: UIViewController {
    private enum Rows: Int, CaseIterable {
        case title = 0
        case tagline = 1

        static func count() -> Int {
            return allCases.count
        }

        func matches(_ row: Int) -> Bool {
            return row == self.rawValue
        }
    }

    private struct Constants {
        static let bottomMargin: CGFloat = 63.0
    }

    private let completion: SIteInformationCompletion

    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var nextStep: NUXButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonWrapper: UIView!

    private lazy var headerData: SiteCreationHeaderData = {
        let title = NSLocalizedString("Basic information", comment: "Create site, step 3. Select basic information. Title")
        let subtitle = NSLocalizedString("Tell us more about the site you are creating.", comment: "Create site, step 3. Select basic information. Subtitle")

        return SiteCreationHeaderData(title: title, subtitle: subtitle)
    }()

    init(completion: @escaping SIteInformationCompletion) {
        self.completion = completion
        super.init(nibName: String(describing: type(of: self)), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        applyTitle()
        setupBackground()
        setupTable()
        setupButtonWrapper()
        setupNextButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startListeningToKeyboardNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningToKeyboardNotifications()
    }

    private func applyTitle() {
        title = NSLocalizedString("2 of 3", comment: "Site creation. Step 2. Screen title")
    }

    private func setupBackground() {
        view.backgroundColor = WPStyleGuide.greyLighten30()
    }

    private func setupTable() {
        setupTableBackground()
        registerCell()
        setupHeader()
        setupFooter()

        table.dataSource = self
    }

    private func setupTableBackground() {
        table.backgroundColor = WPStyleGuide.greyLighten30()
    }
    private func registerCell() {
        table.register(
            InlineEditableNameValueCell.defaultNib,
            forCellReuseIdentifier: InlineEditableNameValueCell.defaultReuseID
        )
    }

    private func setupButtonWrapper() {
        buttonWrapper.backgroundColor = WPStyleGuide.greyLighten30()
        //buttonWrapper.
    }

    private func setupNextButton() {
        nextStep.addTarget(self, action: #selector(goNext), for: .touchUpInside)

        setupButtonAsSkip()
    }

    private func setupButtonAsSkip() {
        let buttonTitle = NSLocalizedString("Skip", comment: "Button to progress to the next step")
        nextStep.setTitle(buttonTitle, for: .normal)
        nextStep.accessibilityLabel = buttonTitle
        nextStep.accessibilityHint = NSLocalizedString("Navigates to the next step without making changes", comment: "Site creation. Navigates tot he next step")

        nextStep.isPrimary = false
    }

    private func setupButtonAsNext() {
        let buttonTitle = NSLocalizedString("Next", comment: "Button to progress to the next step")
        nextStep.setTitle(buttonTitle, for: .normal)
        nextStep.accessibilityLabel = buttonTitle
        nextStep.accessibilityHint = NSLocalizedString("Navigates to the next step saving changes", comment: "Site creation. Navigates tot he next step")

        nextStep.isPrimary = true
    }

    private func setupHeader() {
        let header = TitleSubtitleHeader(frame: .zero)
        header.setTitle(headerData.title)
        header.setSubtitle(headerData.subtitle)

        table.tableHeaderView = header

        NSLayoutConstraint.activate([
            header.centerXAnchor.constraint(equalTo: table.centerXAnchor),
            header.widthAnchor.constraint(equalTo: table.widthAnchor),
            header.topAnchor.constraint(equalTo: table.topAnchor)
            ])

        table.tableHeaderView?.layoutIfNeeded()
        table.tableHeaderView = table.tableHeaderView
    }

    private func setupFooter() {
        let footer = UIView(frame: CGRect(x: 0.0, y: 0.0, width: table.frame.width, height: 42.0))

        let title = UILabel(frame: .zero)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.textAlignment = .natural
        title.numberOfLines = 0
        title.textColor = WPStyleGuide.greyDarken20()
        title.font = UIFont.preferredFont(forTextStyle: .footnote)
        title.text = TableStrings.footer

        footer.addSubview(title)

        NSLayoutConstraint.activate([
            title.heightAnchor.constraint(equalTo: footer.heightAnchor),
            title.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: 16.0),
            title.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -1 * 16.0),
            title.topAnchor.constraint(equalTo: footer.topAnchor)
            ])

        table.tableFooterView = footer
    }

    @objc
    private func goNext() {
        let collectedData = SiteInformation(title: titleString(), tagLine: taglineString())
        completion(collectedData)
    }

    private func titleString() -> String {
        return cell(at: IndexPath(row: Rows.title.rawValue, section: 0))?.valueTextField.text ?? ""
    }

    private func taglineString() -> String {
        return cell(at: IndexPath(row: Rows.tagline.rawValue, section: 0))?.valueTextField.text ?? ""
    }

    private func cell(at: IndexPath) -> InlineEditableNameValueCell? {
        return table.cellForRow(at: at) as? InlineEditableNameValueCell
    }
}

extension SiteInformationWizardContent: UITableViewDataSource {
    private enum TableStrings {
        static let site = NSLocalizedString("Site Title", comment: "Site info. Title")
        static let tagline = NSLocalizedString("Tagline", comment: "Site info. Tagline")
        static let taglinePlaceholder = NSLocalizedString("Optional Tagline", comment: "Site info. Tagline placeholder")
        static let footer = NSLocalizedString("The tagline is a short line of text shown right below the title", comment: "Site info. Table footer.")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Rows.count()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: InlineEditableNameValueCell.defaultReuseID, for: indexPath) as? InlineEditableNameValueCell else {
            assertionFailure("SiteInformationWizardContent. Could not dequeue a cell")
            return UITableViewCell()
        }

        configure(cell, index: indexPath)
        return cell
    }

    private func configure(_ cell: InlineEditableNameValueCell, index: IndexPath) {
        if Rows.title.matches(index.row) {
            cell.nameLabel.text = TableStrings.site
            cell.valueTextField.placeholder = TableStrings.site
        }

        if Rows.tagline.matches(index.row) {
            cell.nameLabel.text = TableStrings.tagline
            cell.valueTextField.placeholder = TableStrings.taglinePlaceholder
        }

        cell.valueTextField.textColor = WPStyleGuide.greyDarken30()

        if cell.delegate == nil {
            cell.delegate = self
        }
    }
}

extension SiteInformationWizardContent: InlineEditableNameValueCellDelegate {
    func inlineEditableNameValueCell(_ cell: InlineEditableNameValueCell,
                                      valueTextFieldDidChange valueTextField: UITextField) {
        updateButton()
    }

    private func updateButton() {
        formIsFilled() ? setupButtonAsNext() : setupButtonAsSkip()
    }

    private func formIsFilled() -> Bool {
        return !titleString().isEmpty || !taglineString().isEmpty
    }
}

extension SiteInformationWizardContent {
    private func startListeningToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    private func stopListeningToKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc
    private func keyboardDidShow(_ notification: Foundation.Notification) {
        guard let payload = KeyboardInfo(notification) else { return }
        let keyboardScreenFrame = payload.frameEnd

        let keyboardFrame = view.convert(keyboardScreenFrame, from: nil)
        let keyboardHeight = keyboardFrame.origin.y - (Constants.bottomMargin + 36)

        let animationDuration = payload.animationDuration

        bottomConstraint.constant = keyboardHeight
        view.setNeedsUpdateConstraints()

        UIView.animate(withDuration: animationDuration,
                       delay: 0,
                       options: .beginFromCurrentState,
                       animations: { [weak self] in
                        self?.view.layoutIfNeeded()
        },
                       completion: nil)
    }

    @objc
    private func keyboardWillHide(_ notification: Foundation.Notification) {
        bottomConstraint.constant = Constants.bottomMargin
    }

    private func localKeyboardFrameFromNotification(_ notification: Foundation.Notification) -> CGRect {
        let key = UIResponder.keyboardFrameEndUserInfoKey
        guard let keyboardFrame = (notification.userInfo?[key] as? NSValue)?.cgRectValue else {
            return .zero
        }

        return view.convert(keyboardFrame, from: nil)
    }
}

private struct KeyboardInfo {
    var animationCurve: UIView.AnimationCurve
    var animationDuration: Double
    var isLocal: Bool
    var frameBegin: CGRect
    var frameEnd: CGRect
}

extension KeyboardInfo {
    init?(_ notification: Foundation.Notification) {
        print("=== notification name ", notification.name)
        print("=== will show ", UIResponder.keyboardWillShowNotification)
        guard notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillHideNotification else {
            print("==== returning nil")
            return nil

        }
        let u = notification.userInfo!

        animationCurve = UIView.AnimationCurve(rawValue: u[UIWindow.keyboardAnimationCurveUserInfoKey] as! Int)!
        animationDuration = u[UIWindow.keyboardAnimationDurationUserInfoKey] as! Double
        isLocal = u[UIWindow.keyboardIsLocalUserInfoKey] as! Bool
        frameBegin = u[UIWindow.keyboardFrameBeginUserInfoKey] as! CGRect
        frameEnd = u[UIWindow.keyboardFrameEndUserInfoKey] as! CGRect
    }
}
