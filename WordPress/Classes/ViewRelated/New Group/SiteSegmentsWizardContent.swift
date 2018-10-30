
import UIKit

final class SiteSegmentsWizardContent: UIViewController {
    private let service: SiteSegmentsService

    init(service: SiteSegmentsService) {
        self.service = service
        super.init(nibName: String(describing: type(of: self)), bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
