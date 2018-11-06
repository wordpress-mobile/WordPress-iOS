import UIKit

/// Contains the UI corresponsing to the list of segments
final class SiteSegmentsWizardContent: UIViewController {
    private let service: SiteSegmentsService
    private var dataCoordinator: (UITableViewDataSource & UITableViewDelegate)?
    private let selection: (SiteSegment) -> Void

    @IBOutlet weak var table: UITableView!

    init(service: SiteSegmentsService, selection: @escaping (SiteSegment) -> Void) {
        self.service = service
        self.selection = selection
        super.init(nibName: String(describing: type(of: self)), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupTable()

        fetchSegments()
    }

    private func setupTable() {
        let cellName = SiteSegmentsCell.cellReuseIdentifier()
        let nib = UINib(nibName: cellName, bundle: nil)
        table.register(nib, forCellReuseIdentifier: cellName)
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
        dataCoordinator = SiteCreationDataCoordinator(data: data, cellType: SiteSegmentsCell.self, selection: didSelect)
        table.dataSource = dataCoordinator
        table.delegate = dataCoordinator
        table.reloadData()
    }

    private func didSelect(_ segment: SiteSegment) {
        selection(segment)
    }
}
