
import UIKit

final class SiteSegmentsWizardContent: UIViewController {
    private let service: SiteSegmentsService
    private var dataSource: UITableViewDataSource?

    @IBOutlet weak var table: UITableView!

    init(service: SiteSegmentsService) {
        self.service = service
        super.init(nibName: String(describing: type(of: self)), bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fetchSegments()
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
        print("=== handling error===")
    }

    private func handleData(_ data: [SiteSegment]) {
        dataSource = SiteSegmentsDataSource(data: data)
    }
}
