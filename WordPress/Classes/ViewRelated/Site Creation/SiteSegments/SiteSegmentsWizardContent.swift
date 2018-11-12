import UIKit
import WordPressShared

/// Contains the UI corresponsing to the list of segments
final class SiteSegmentsWizardContent: UIViewController {
    private let service: SiteSegmentsService
    private var dataCoordinator: (UITableViewDataSource & UITableViewDelegate)?
    private let selection: (SiteSegment) -> Void

    @IBOutlet weak var table: UITableView!

    private lazy var headerData: SiteCreationHeaderData = {
        let title = NSLocalizedString("Tell us what kind of site you'd like to make", comment: "Create site, step 1. Select type of site. Title")
        let subtitle = NSLocalizedString("This helps us suggest a solid foundation. But you're never locked in -- all sites evolve!", comment: "Create site, step 1. Select type of site. Subtitle")
        return SiteCreationHeaderData(title: title, subtitle: subtitle)
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

        setupBackground()
        setupTable()
    }

    private func setupBackground() {
        view.backgroundColor = WPStyleGuide.greyLighten30()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        fetchSegments()
    }

    private func setupTable() {
        setupCell()
        setupHeader()
    }

    private func setupCell() {
        let cellName = SiteSegmentsCell.cellReuseIdentifier()
        let nib = UINib(nibName: cellName, bundle: nil)
        table.register(nib, forCellReuseIdentifier: cellName)
    }

    private func setupHeader() {
        let header = TitleSubtitleHeader(frame: .zero)
        header.setTitle(headerData.title)
        header.setSubtitle(headerData.subtitle)

        table.tableHeaderView = header

        // This is the only way I found to insert a stack view into the header without breaking the autolayout constraints. We do something similar in Reader
        header.centerXAnchor.constraint(equalTo: table.centerXAnchor).isActive = true
        header.widthAnchor.constraint(equalTo: table.widthAnchor).isActive = true
        header.topAnchor.constraint(equalTo: table.topAnchor).isActive = true

        table.tableHeaderView?.layoutIfNeeded()
        table.tableHeaderView = table.tableHeaderView
    }

    private func fetchSegments() {
        service.siteSegments(for: Locale.current) { [weak self] results in
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
