import UIKit

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

    private let segment: SiteSegment?
    private let completion: SIteInformationCompletion

    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var nextStep: UIButton!

    private lazy var headerData: SiteCreationHeaderData = {
        let title = NSLocalizedString("Basic information", comment: "Create site, step 3. Select basic information. Title")
        let subtitle = NSLocalizedString("Tell us more about the site you are creating.", comment: "Create site, step 3. Select basic information. Subtitle")

        return SiteCreationHeaderData(title: title, subtitle: subtitle)
    }()

    init(segment: SiteSegment?, completion: @escaping SIteInformationCompletion) {
        self.segment = segment
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
        setupNextButton()
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
        //table.delegate = self
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

    private func setupNextButton() {
        nextStep.addTarget(self, action: #selector(goNext), for: .touchUpInside)

        setupButtonAsSkip()
    }

    private func setupButtonAsSkip() {
        let buttonTitle = NSLocalizedString("Skip", comment: "Button to progress to the next step")
        nextStep.setTitle(buttonTitle, for: .normal)
        nextStep.accessibilityLabel = buttonTitle
        nextStep.accessibilityHint = NSLocalizedString("Navigates to the next step without making changes", comment: "Site creation. Navigates tot he next step")
    }

    private func setupButtonAsNext() {
        let buttonTitle = NSLocalizedString("Next", comment: "Button to progress to the next step")
        nextStep.setTitle(buttonTitle, for: .normal)
        nextStep.accessibilityLabel = buttonTitle
        nextStep.accessibilityHint = NSLocalizedString("Navigates to the next step saving changes", comment: "Site creation. Navigates tot he next step")
    }

    private func setupHeader() {
        let header = TitleSubtitleHeader(frame: .zero)
        header.setTitle(headerData.title)
        header.setSubtitle(headerData.subtitle)

        table.tableHeaderView = header

        NSLayoutConstraint.activate([
            header.centerXAnchor.constraint(equalTo: table.centerXAnchor),
            header.widthAnchor.constraint(equalTo: table.layoutMarginsGuide.widthAnchor),
            header.topAnchor.constraint(equalTo: table.layoutMarginsGuide.topAnchor)
            ])

        table.tableHeaderView?.layoutIfNeeded()
        table.tableHeaderView = table.tableHeaderView
    }

    private func setupFooter() {
        let footer = UIView(frame: CGRect(x: 0.0, y: 0.0, width: table.frame.width, height: 60.0))

        let title = UILabel(frame: .zero)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.textAlignment = .natural
        title.numberOfLines = 0
        title.textColor = WPStyleGuide.greyDarken20()
        title.font = UIFont.preferredFont(forTextStyle: .footnote)
        title.text = TableStrings.footer

        footer.addSubview(title)

        NSLayoutConstraint.activate([
            title.heightAnchor.constraint(equalTo: footer.readableContentGuide.heightAnchor),
            title.leadingAnchor.constraint(equalTo: footer.readableContentGuide.leadingAnchor),
            title.trailingAnchor.constraint(equalTo: footer.readableContentGuide.trailingAnchor),
            title.topAnchor.constraint(equalTo: footer.topAnchor)
            ])

        table.tableFooterView = footer
    }

    @objc
    private func goNext() {
        guard let titleCell = cell(at: IndexPath(row: Rows.title.rawValue, section: 0)),
            let taglineCell = cell(at: IndexPath(row: Rows.tagline.rawValue, section: 0)) else {
            return
        }

        let collectedData = SiteInformation(title: titleCell.valueTextField.text ?? "", tagLine: taglineCell.valueTextField.text)
        completion(collectedData)
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
    }
}
