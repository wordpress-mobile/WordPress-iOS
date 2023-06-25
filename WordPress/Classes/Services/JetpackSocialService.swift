import WordPressKit
import CoreData

class JetpackSocialService: CoreDataService {

    // TODO: (dvdchr) Is this testable?
    private lazy var remote: JetpackSocialServiceRemote = {
        let api = coreDataStack.performQuery { context in
            return WordPressComRestApi.defaultV2Api(in: context)
        }
        return .init(wordPressComRestApi: api)
    }()

    // TODO: (dvdchr) Docs
    ///
    /// - Parameter siteID: Int
    /// - Returns: PublicizeInfo
    func fetchPublicizeInfo(for siteID: Int) async -> Result<PublicizeInfo?, Error> {
        await withCheckedContinuation { continuation in
            remote.fetchPublicizeInfo(for: siteID) { result in
                switch result {
                case .success(let remotePublicizeInfo):
                    // TODO: Convert RemotePublicizeInfo to PublicizeInfo.
                    // TODO: If it's nil, delete the existing entry from Core Data.
                    break

                case .failure(let error):
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }

}

// MARK: - Private Methods

private extension JetpackSocialService {


}
