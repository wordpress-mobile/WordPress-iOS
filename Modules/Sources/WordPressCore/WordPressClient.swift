import Foundation
import WordPressAPI

public actor WordPressClient {

    public let api: WordPressAPI
    private let rootUrl: String

    public init(api: WordPressAPI, rootUrl: ParsedUrl) {
        self.api = api
        self.rootUrl = rootUrl.url()
    }

}
