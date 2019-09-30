import Foundation
import WordPressKit

extension WordPressComRestApi {
    @objc public static func defaultApi(oAuthToken: String? = nil,
                                        userAgent: String? = nil,
                                        localeKey: String = WordPressComRestApi.LocaleKeyDefault) -> WordPressComRestApi {
        return WordPressComRestApi(oAuthToken: oAuthToken,
                                   userAgent: userAgent,
                                   localeKey: localeKey,
                                   baseUrlString: Environment.current.wordPressComApiBase)
    }
}
