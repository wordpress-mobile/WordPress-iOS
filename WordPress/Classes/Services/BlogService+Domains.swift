import Combine
import Foundation

extension BlogService {
    private static var domainCancellablesAssociationKey = "org.wordpress.blogservice.domaincancellables"

    var refreshDomainsCancellable: AnyCancellable? {
        get {
            return (objc_getAssociatedObject(self, &Self.domainCancellablesAssociationKey) as? AnyCancellable)
        }

        set(newValue) {
            objc_setAssociatedObject(self, &Self.domainCancellablesAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    @objc
    func refreshDomains(for blog: Blog, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        guard let account = blog.account,
              let blogID = blog.dotComID else {

            return
        }

        let service = DomainsService(managedObjectContext: managedObjectContext, account: account)

        refreshDomainsCancellable = service.refreshDomains(siteID: blogID.intValue)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    failure(error)
                case .finished:
                    success()
                }
            }, receiveValue: {})
    }
}
