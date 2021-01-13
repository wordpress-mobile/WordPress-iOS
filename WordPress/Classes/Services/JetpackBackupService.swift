import Foundation

@objc class JetpackBackupService: LocalCoreDataService {

    private lazy var service: JetpackBackupServiceRemote = {
        let api = WordPressComRestApi.defaultApi(in: managedObjectContext,
                                                 localeKey: WordPressComRestApi.LocaleKeyV2)

        return JetpackBackupServiceRemote(wordPressComRestApi: api)
    }()

    func prepareBackup(for blog: Blog, success: @escaping (JetpackBackup) -> Void, failure: @escaping (Error) -> Void) {
        guard let siteID = blog.dotComID?.intValue else {
            return
        }

        service.prepareBackup(siteID, success: success, failure: failure)
    }

    func getBackupStatus(for blog: Blog, success: @escaping (JetpackBackup) -> Void, failure: @escaping (Error) -> Void) {
        guard let siteID = blog.dotComID?.intValue else {
            return
        }

        service.getBackupStatus(siteID, success: success, failure: failure)
    }

}
