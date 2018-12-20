import UIKit
import WordPressKit

/// Contains the UI corresponding to the list of verticals
final class VerticalsWizardContent: UIViewController {
    private let segment: SiteSegment?
    private let service: SiteVerticalsService
    private var data: [SiteVertical]
    private let selection: (SiteVertical) -> Void

    private let throttle = Scheduler(seconds: 1)

    @IBOutlet weak var table: UITableView!

    private struct StyleConstants {
        static let rowHeight: CGFloat = 44.0
        static let separatorInset = UIEdgeInsets(top: 0, left: 16.0, bottom: 0, right: 0)
    }

    private lazy var headerData: SiteCreationHeaderData = {
        let title = NSLocalizedString("What's the focus of your business?", comment: "Create site, step 2. Select focus of the business. Title")
        let subtitle = NSLocalizedString("We'll use your answer to add sections to your website.", comment: "Create site, step 2. Select focus of the business. Subtitle")

        return SiteCreationHeaderData(title: title, subtitle: subtitle)
    }()

    init(segment: SiteSegment?, service: SiteVerticalsService, selection: @escaping (SiteVertical) -> Void) {
        self.segment = segment
        self.service = service
        self.selection = selection
        self.data = []
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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        table.layoutHeaderView()
    }

    private func applyTitle() {
        title = NSLocalizedString("1 of 3", comment: "Site creation. Step 2. Screen title")
    }

    private func setupBackground() {
        view.backgroundColor = WPStyleGuide.greyLighten30()
    }

    private func setupTable() {
        table.dataSource = self
        table.delegate = self
        setupTableBackground()
        setupTableSeparator()
        setupCells()
        setupHeader()
        setupConstraints()
        hideSeparators()
    }

    private func setupTableBackground() {
        table.backgroundColor = WPStyleGuide.greyLighten30()
    }

    private func setupTableSeparator() {
        table.separatorColor = WPStyleGuide.greyLighten20()
    }

    private func hideSeparators() {
        table.tableFooterView = UIView(frame: .zero)
    }

    private func setupCells() {
        registerCells()
        setupCellHeight()
    }

    private func setupCellHeight() {
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = StyleConstants.rowHeight
        table.separatorInset = StyleConstants.separatorInset
    }

    private func registerCells() {
        registerCell(identifier: VerticalsCell.cellReuseIdentifier())
        registerCell(identifier: NewVerticalCell.cellReuseIdentifier())
    }

    private func registerCell(identifier: String) {
        let nib = UINib(nibName: identifier, bundle: nil)
        table.register(nib, forCellReuseIdentifier: identifier)
    }

    private func setupHeader() {
        let header = TitleSubtitleTextfieldHeader(frame: .zero)
        header.setTitle(headerData.title)
        header.setSubtitle(headerData.subtitle)

        header.textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        let placeholderText = NSLocalizedString("e.g. Landscaping, Consulting... etc.", comment: "Site creation. Select focus of your business, search field placeholder")
        let attributes = WPStyleGuide.defaultSearchBarTextAttributesSwifted(WPStyleGuide.grey())
        let attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        header.textField.attributedPlaceholder = attributedPlaceholder

        table.tableHeaderView = header

        NSLayoutConstraint.activate([
            header.widthAnchor.constraint(equalTo: table.widthAnchor),
            header.centerXAnchor.constraint(equalTo: table.centerXAnchor),
        ])
    }

    private func setupConstraints() {
        table.cellLayoutMarginsFollowReadableWidth = true

        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: view.prevailingLayoutGuide.topAnchor),
            table.bottomAnchor.constraint(equalTo: view.prevailingLayoutGuide.bottomAnchor),
            table.leadingAnchor.constraint(equalTo: view.prevailingLayoutGuide.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.prevailingLayoutGuide.trailingAnchor),
        ])
    }

    @objc
    private func textChanged(sender: UITextField) {
        guard let searchTerm = sender.text, searchTerm.isEmpty == false else {
            return
        }

        throttle.throttle { [weak self] in
            self?.fetchVerticals(searchTerm)
        }
    }

    private func fetchVerticals(_ searchTerm: String) {
        guard let segment = segment else {
            return
        }

        service.verticals(for: Locale.current, type: segment) {  [weak self] results in
            switch results {
            case .error(let error):
                self?.handleError(error)
            case .success(let data):
                self?.handleData(data)
            }
        }
    }

    private func handleError(_ error: Error) {
        debugPrint("=== handling error===")
    }

    private func handleData(_ data: [SiteVertical]) {
        self.data = data
        table.reloadData()
    }

    private func didSelect(_ vertical: SiteVertical) {
        selection(vertical)
    }
}

extension VerticalsWizardContent: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let vertical = data[indexPath.row]
        let cell = configureCell(vertical: vertical, indexPath: indexPath)

        addBorder(cell: cell, at: indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vertical = data[indexPath.row]
        didSelect(vertical)
    }
}

private extension VerticalsWizardContent {
    private func configureCell(vertical: SiteVertical, indexPath: IndexPath) -> UITableViewCell {
        let identifier = cellIdentifier(vertical: vertical)

        if var cell = table.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? SiteVerticalPresenter {
            cell.vertical = vertical

            return cell as! UITableViewCell
        }

        return UITableViewCell()
    }

    private func cellIdentifier(vertical: SiteVertical) -> String {
        return vertical.isNew ? NewVerticalCell.cellReuseIdentifier() : VerticalsCell.cellReuseIdentifier()
    }

    private func addBorder(cell: UITableViewCell, at: IndexPath) {
        let row = at.row
        if row == 0 {
            cell.addTopBorder(withColor: WPStyleGuide.greyLighten20())
        }

        if row == data.count - 1 {
            cell.addBottomBorder(withColor: WPStyleGuide.greyLighten20())
        }
    }
}
