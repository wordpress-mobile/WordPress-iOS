import Foundation
import WordPressKit

class QRLoginService: LocalCoreDataService {
    private let service: QRLoginServiceRemote

    init(managedObjectContext: NSManagedObjectContext, remoteService: QRLoginServiceRemote? = nil) {
        self.service = remoteService ?? QRLoginServiceRemote(wordPressComRestApi: WordPressComRestApi.defaultApi(in: managedObjectContext, localeKey: WordPressComRestApi.LocaleKeyV2))
        super.init()
    }

    func validate(token: QRLoginToken, success: @escaping(QRLoginValidationResponse) -> Void, failure: @escaping(Error?, QRLoginError?) -> Void) {
        service.validate(token: token.token, data: token.data, success: success, failure: failure)
    }

    func authenticate(token: QRLoginToken, success: @escaping(Bool) -> Void, failure: @escaping(Error) -> Void) {
        service.authenticate(token: token.token, data: token.data, success: success, failure: failure)
    }
}
