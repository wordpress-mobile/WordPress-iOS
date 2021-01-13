import Foundation

@objc class JetpackBackupService: LocalCoreDataService {

    private lazy var service: JetpackBackupServiceRemote = {
        let api = WordPressComRestApi.defaultApi(in: managedObjectContext,
                                                 localeKey: WordPressComRestApi.LocaleKeyV2)

        return JetpackBackupServiceRemote(wordPressComRestApi: api)
    }()

    func prepareBackup(for site: JetpackSiteRef, success: @escaping (JetpackBackup) -> Void, failure: @escaping (Error) -> Void) {
        service.prepareBackup(site.siteID, success: success, failure: failure)
    }

    func getBackupStatus(for site: JetpackSiteRef, downloadID: Int, success: @escaping (JetpackBackup) -> Void, failure: @escaping (Error) -> Void) {
        service.getBackupStatus(site.siteID, downloadID: downloadID, success: success, failure: failure)
    }

}
