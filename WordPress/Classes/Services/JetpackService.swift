import Foundation

class JetpackService {
    private var context: NSManagedObjectContext?
    private let service = JetpackServiceRemote(wordPressComRestApi: WordPressComRestApi())

    init(managedObjectContext context: NSManagedObjectContext = ContextManager.shared.mainContext) {
        self.context = context
    }

    func installJetpack(url: String,
                        username: String,
                        password: String,
                        completion: @escaping (Bool, JetpackInstallError?) -> Void) {
        service.installJetpack(url: url, username: username, password: password, completion: completion)
    }
}
