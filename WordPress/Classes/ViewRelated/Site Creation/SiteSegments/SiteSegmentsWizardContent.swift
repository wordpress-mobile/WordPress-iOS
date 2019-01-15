import UIKit
import WordPressShared

/// Contains the UI corresponsing to the list of segments
final class SiteSegmentsWizardContent: UIViewController {
    private let service: SiteSegmentsService
    private var dataCoordinator: (UITableViewDataSource & UITableViewDelegate)?
    private let selection: (SiteSegment) -> Void

    @IBOutlet weak var table: UITableView!

    private struct StyleConstants {
        static let rowHeight: CGFloat = 72.0
        static let separatorInset = UIEdgeInsets(top: 0, left: 64.0, bottom: 0, right: 0)
    }

    private lazy var headerData: SiteCreationHeaderData = {
        let title = NSLocalizedString("Tell us what kind of site you'd like to make", comment: "Create site, step 1. Select type of site. Title")
        let subtitle = NSLocalizedString("This helps us make recommendations. But you're never locked in -- all sites evolve!", comment: "Create site, step 1. Select type of site. Subtitle")
        let dashSubtitle = subtitle.replacingMatches(of: "--", with: "\u{2014}")
        return SiteCreationHeaderData(title: title, subtitle: dashSubtitle)
    }()

    init(service: SiteSegmentsService, selection: @escaping (SiteSegment) -> Void) {
        self.service = service
        self.selection = selection
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
        initCancelButton()
    }

    private func applyTitle() {
        title = NSLocalizedString("Create Site", comment: "Site creation. Step 1. Screen title")
    }

    private func setupBackground() {
        view.backgroundColor = WPStyleGuide.greyLighten30()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        fetchSegments()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        table.layoutHeaderView()
    }

    private func setupTable() {
        setupTableBackground()
        setupTableSeparator()
        setupCell()
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

    private func setupCell() {
        registerCell()
        setupCellHeight()
    }

    private func registerCell() {
        let cellName = SiteSegmentsCell.cellReuseIdentifier()
        let nib = UINib(nibName: cellName, bundle: nil)
        table.register(nib, forCellReuseIdentifier: cellName)
    }

    private func setupCellHeight() {
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = StyleConstants.rowHeight
        table.separatorInset = StyleConstants.separatorInset
    }

    private func setupHeader() {
        print("==== table width ===", table.frame.width )
        let initialHeaderFrame = CGRect(x: 0, y: 0, width: Int(table.frame.width), height: 0)
        let header = TitleSubtitleHeader(frame: initialHeaderFrame)
        header.setTitle(headerData.title)
        header.setSubtitle(headerData.subtitle)

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

    private func initCancelButton() {
        navigationItem.leftBarButtonItem = cancelButton()
    }

    private func cancelButton() -> UIBarButtonItem {
        let literal = NSLocalizedString("Cancel", comment: "Cancel button. Site creation modal popover.")
        return UIBarButtonItem(title: literal, style: .plain, target: self, action: #selector(cancelSiteCreation))
    }

    @objc
    private func cancelSiteCreation() {
        dismiss(animated: true, completion: nil)
    }

    private func fetchSegments() {
        service.siteSegments(for: Locale.current) { [weak self] results in
            switch results {
            case .failure(let error):
                self?.handleError(error)
            case .success(let data):
                self?.handleData(data)
            }
        }
    }

    private func handleError(_ error: SiteSegmentsError) {
        debugPrint("=== handling error===")
    }

    private func handleData(_ data: [SiteSegment]) {
        dataCoordinator = TableDataCoordinator(data: data, cellType: SiteSegmentsCell.self, selection: didSelect)
        table.dataSource = dataCoordinator
        table.delegate = dataCoordinator
        table.reloadData()
    }

    private func didSelect(_ segment: SiteSegment) {
        selection(segment)
    }
}
