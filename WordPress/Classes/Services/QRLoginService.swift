import Foundation
import WordPressKit

class QRLoginService {
    private let service: QRLoginServiceRemote

    init(coreDataStack: CoreDataStack, remoteService: QRLoginServiceRemote? = nil) {
        self.service = remoteService ??
            coreDataStack.performQuery({ QRLoginServiceRemote(wordPressComRestApi: WordPressComRestApi.defaultApi(in: $0, localeKey: WordPressComRestApi.LocaleKeyV2)) })
    }

    func validate(token: QRLoginToken, success: @escaping(QRLoginValidationResponse) -> Void, failure: @escaping(Error?, QRLoginError?) -> Void) {
        service.validate(token: token.token, data: token.data, success: success, failure: failure)
    }

    func authenticate(token: QRLoginToken, success: @escaping(Bool) -> Void, failure: @escaping(Error) -> Void) {
        service.authenticate(token: token.token, data: token.data, success: success, failure: failure)
    }
}
