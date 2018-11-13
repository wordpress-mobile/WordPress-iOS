import UIKit

final class SiteInfoWizardContent: UIViewController {
    private let service: SiteInformationService

    init(service: SiteInformationService) {
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
