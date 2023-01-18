import Foundation

class JetpackBackupService {

    private let coreDataStack: CoreDataStack

    private lazy var service: JetpackBackupServiceRemote = {
        var api: WordPressComRestApi!
        coreDataStack.mainContext.performAndWait {
            api = WordPressComRestApi.defaultApi(in: self.coreDataStack.mainContext, localeKey: WordPressComRestApi.LocaleKeyV2)
        }

        return JetpackBackupServiceRemote(wordPressComRestApi: api)
    }()

    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }

    func prepareBackup(for site: JetpackSiteRef,
                       rewindID: String? = nil,
                       restoreTypes: JetpackRestoreTypes? = nil,
                       success: @escaping (JetpackBackup) -> Void,
                       failure: @escaping (Error) -> Void) {
        service.prepareBackup(site.siteID, rewindID: rewindID, types: restoreTypes, success: success, failure: failure)
    }

    func getBackupStatus(for site: JetpackSiteRef, downloadID: Int, success: @escaping (JetpackBackup) -> Void, failure: @escaping (Error) -> Void) {
        service.getBackupStatus(site.siteID, downloadID: downloadID, success: success, failure: failure)
    }

    func getAllBackupStatus(for site: JetpackSiteRef, success: @escaping ([JetpackBackup]) -> Void, failure: @escaping (Error) -> Void) {
        service.getAllBackupStatus(site.siteID, success: success, failure: failure)
    }

    func dismissBackupNotice(site: JetpackSiteRef, downloadID: Int) {
        service.markAsDismissed(site.siteID, downloadID: downloadID, success: {}, failure: { _ in })
    }

}
