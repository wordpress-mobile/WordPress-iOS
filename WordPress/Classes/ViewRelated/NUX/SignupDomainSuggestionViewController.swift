import UIKit

class SignupDomainSuggestionViewController: UIViewController {

    var service: DomainsService?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let moc = NSManagedObjectContext()
        let api = WordPressComRestApi(oAuthToken: "")
        let service = DomainsService(managedObjectContext: moc, remote: DomainsServiceRemote(wordPressComRestApi: api))
        service.getDomainSuggestions(base: "test suggest")
    }
}
