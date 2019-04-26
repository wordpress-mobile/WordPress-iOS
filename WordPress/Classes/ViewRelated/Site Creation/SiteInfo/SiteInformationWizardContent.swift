import UIKit
import WordPressAuthenticator

typealias SiteInformationCompletion = (SiteInformation) -> Void

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
        static let bottomMargin: CGFloat = 0.0
        static let footerHeight: CGFloat = 42.0
        static let footerVerticalMargin: CGFloat = 6.0
        static let footerHorizontalMargin: CGFloat = 16.0
        static let rowHeight: CGFloat = 44.0
    }

    private let completion: SiteInformationCompletion

    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var nextStep: NUXButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonWrapper: ShadowView!

    private lazy var headerData: SiteCreationHeaderData = {
        let title = NSLocalizedString("Basic information", comment: "Create site, step 3. Select basic information. Title")
        let subtitle = NSLocalizedString("Tell us more about the site you are creating.", comment: "Create site, step 3. Select basic information. Subtitle")

        return SiteCreationHeaderData(title: title, subtitle: subtitle)
    }()

    init(completion: @escaping SiteInformationCompletion) {
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
        WPAnalytics.track(.enhancedSiteCreationBasicInformationViewed)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startListeningToKeyboardNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopListeningToKeyboardNotifications()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        table.layoutHeaderView()
    }

    private func applyTitle() {
        title = NSLocalizedString("2 of 3", comment: "Site creation. Step 2. Screen title")
    }

    private func setupBackground() {
        view.backgroundColor = WPStyleGuide.greyLighten30()
    }

    private func setupTable() {
        setupTableBackground()
        setupTableSeparator()
        registerCell()
        setupCellHeight()
        setupHeader()
        setupFooter()
        setupConstraints()

        table.dataSource = self
    }

    private func setupTableBackground() {
        table.backgroundColor = WPStyleGuide.greyLighten30()
    }

    private func setupTableSeparator() {
        table.separatorColor = WPStyleGuide.greyLighten20()
    }

    private func registerCell() {
        table.register(
            InlineEditableNameValueCell.defaultNib,
            forCellReuseIdentifier: InlineEditableNameValueCell.defaultReuseID
        )
    }

    private func setupCellHeight() {
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = Constants.rowHeight
    }

    private func setupButtonWrapper() {
        buttonWrapper.backgroundColor = WPStyleGuide.greyLighten30()
    }

    private func setupNextButton() {
        nextStep.addTarget(self, action: #selector(goNext), for: .touchUpInside)

        setupButtonAsSkip()
    }

    private func setupButtonAsSkip() {
        let buttonTitle = NSLocalizedString("Skip", comment: "Button to progress to the next step")
        nextStep.setTitle(buttonTitle, for: .normal)
        nextStep.accessibilityLabel = buttonTitle
        nextStep.accessibilityHint = NSLocalizedString("Navigates to the next step without making changes", comment: "Site creation. Navigates to the next step")

        nextStep.isPrimary = false
    }

    private func setupButtonAsNext() {
        let buttonTitle = NSLocalizedString("Next", comment: "Button to progress to the next step")
        nextStep.setTitle(buttonTitle, for: .normal)
        nextStep.accessibilityLabel = buttonTitle
        nextStep.accessibilityHint = NSLocalizedString("Navigates to the next step saving changes", comment: "Site creation. Navigates to the next step")

        nextStep.isPrimary = true
    }

    private func setupHeader() {
        let initialHeaderFrame = CGRect(x: 0, y: 0, width: Int(table.frame.width), height: 0)
        let header = TitleSubtitleHeader(frame: initialHeaderFrame)
        header.setTitle(headerData.title)
        header.setSubtitle(headerData.subtitle)

        header.accessibilityTraits = .header

        table.tableHeaderView = header

        NSLayoutConstraint.activate([
            header.widthAnchor.constraint(equalTo: table.widthAnchor),
            header.centerXAnchor.constraint(equalTo: table.centerXAnchor),
        ])
    }

    private func setupFooter() {
        let footer = UIView(frame: CGRect(x: 0.0, y: 0.0, width: table.frame.width, height: Constants.footerHeight))

        let title = UILabel(frame: .zero)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.textAlignment = .natural
        title.numberOfLines = 0
        title.textColor = WPStyleGuide.greyDarken20()
        title.font = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)
        title.text = TableStrings.footer
        title.adjustsFontForContentSizeCategory = true

        footer.addSubview(title)

        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: Constants.footerHorizontalMargin),
            title.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -1 * Constants.footerHorizontalMargin),
            title.topAnchor.constraint(equalTo: footer.topAnchor, constant: Constants.footerVerticalMargin)
            ])

        table.tableFooterView = footer
    }

    private func setupConstraints() {
        table.cellLayoutMarginsFollowReadableWidth = true

        NSLayoutConstraint.activate([
            table.leadingAnchor.constraint(equalTo: view.prevailingLayoutGuide.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.prevailingLayoutGuide.trailingAnchor),
        ])
    }

    @objc
    private func goNext() {
        let collectedData = SiteInformation(title: titleString(), tagLine: taglineString())
        completion(collectedData)
        trackBasicInformationNextStep()
    }

    private func trackBasicInformationNextStep() {
        if nextStep.isPrimary {
            let basicInformationProperties: [String: AnyObject] = [
                "site_title": titleString() as AnyObject,
                "tagline": taglineString() as AnyObject
            ]

            WPAnalytics.track(.enhancedSiteCreationBasicInformationCompleted, withProperties: basicInformationProperties)
        } else {
            WPAnalytics.track(.enhancedSiteCreationBasicInformationSkipped)
        }
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
        static let footer = NSLocalizedString("The tagline is a short line of text shown right below the title.", comment: "Site info. Table footer.")
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
            cell.valueTextField.attributedPlaceholder = attributedPlaceholder(text: TableStrings.site)
            cell.addTopBorder(withColor: WPStyleGuide.greyLighten20())
        }

        if Rows.tagline.matches(index.row) {
            cell.nameLabel.text = TableStrings.tagline
            cell.valueTextField.attributedPlaceholder = attributedPlaceholder(text: TableStrings.tagline)
            cell.addBottomBorder(withColor: WPStyleGuide.greyLighten20())
        }

        cell.nameLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        cell.nameLabel.textColor = WPStyleGuide.darkGrey()

        cell.valueTextField.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        cell.valueTextField.textColor = WPStyleGuide.greyDarken30()

        if cell.delegate == nil {
            cell.delegate = self
        }
    }

    private func attributedPlaceholder(text: String) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: WPStyleGuide.grey(),
            .font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        ]

        return NSAttributedString(string: text, attributes: attributes)
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
                                               selector: #selector(keyboardWillShow),
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
    private func keyboardWillShow(_ notification: Foundation.Notification) {
        guard let payload = KeyboardInfo(notification) else { return }
        let keyboardScreenFrame = payload.frameEnd

        let convertedKeyboardFrame = view.convert(keyboardScreenFrame, from: nil)

        var constraintConstant = convertedKeyboardFrame.height

        if #available(iOS 11.0, *) {
            let bottomInset = view.safeAreaInsets.bottom
            constraintConstant -= bottomInset
        }

        let animationDuration = payload.animationDuration

        bottomConstraint.constant = constraintConstant
        view.setNeedsUpdateConstraints()

        if table.frame.contains(convertedKeyboardFrame.origin) {
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: constraintConstant, right: 0.0)
            table.contentInset = contentInsets
            table.scrollIndicatorInsets = contentInsets

            buttonWrapper.addShadow()
        }

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
        buttonWrapper.clearShadow()
        bottomConstraint.constant = Constants.bottomMargin
    }
}
