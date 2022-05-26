import Foundation
import WordPressKit

class QRLoginService: LocalCoreDataService {
    private lazy var service: QRLoginServiceRemote = {
        let api = WordPressComRestApi.defaultApi(in: managedObjectContext,
                                                 localeKey: WordPressComRestApi.LocaleKeyV2)

        return QRLoginServiceRemote(wordPressComRestApi: api)
    }()

    func validate(token: QRLoginToken, success: @escaping(QRLoginValidationResponse) -> Void, failure: @escaping(Error?, QRLoginError?) -> Void) {
        service.validate(token: token.token, data: token.data, success: success, failure: failure)
    }

    func authenticate(token: QRLoginToken, success: @escaping(Bool) -> Void, failure: @escaping(Error) -> Void) {
        service.authenticate(token: token.token, data: token.data, success: success, failure: failure)

    }
}
