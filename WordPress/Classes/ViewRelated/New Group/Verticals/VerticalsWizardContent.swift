import UIKit
import WordPressKit

final class VerticalsWizardContent: UIViewController {
    private let service: SiteVerticalsService
    private var dataSource: UITableViewDataSource?

    @IBOutlet weak var search: UITextField!
    @IBOutlet weak var table: UITableView!


    init(service: SiteVerticalsService) {
        self.service = service
        super.init(nibName: String(describing: type(of: self)), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupTable()

        setupSearchField()
    }

    private func setupTable() {
        let cellName = VerticalsCell.cellReuseIdentifier()
        let nib = UINib(nibName: cellName, bundle: nil)
        table.register(nib, forCellReuseIdentifier: cellName)
    }

    private func setupSearchField() {
        search.leftViewMode = .always

        search.addTarget(self, action: #selector(textChanged), for: .editingChanged)
    }

    @objc
    private func textChanged(sender: UITextField) {
        guard let searchTerm = sender.text, searchTerm.isEmpty == false else {
            return
        }

        //this would have to be throttled
        fetchVerticals(searchTerm)
    }

    private func fetchVerticals(_ searchTerm: String) {
        print("searching ", searchTerm)
    }
}
