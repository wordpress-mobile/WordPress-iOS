import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressApiCache

public final actor WordPressClient: Sendable {
    public let siteURL: URL
    public let api: WordPressAPI

    private var _cache: WordPressApiCache?
    public var cache: WordPressApiCache? {
        get {
            if _cache == nil {
                _cache = WordPressApiCache.bootstrap()
            }
            return _cache
        }
    }

    private var _service: WpSelfHostedService?
    public var service: WpSelfHostedService? {
        get {
            if _service == nil, let cache {
                do {
                    _service = try api.createSelfHostedService(cache: cache)
                } catch {
                    NSLog("Failed to create service: \(error)")
                }
            }
            return _service
        }
    }

    public init(api: WordPressAPI, siteURL: URL) {
        self.api = api
        self.siteURL = siteURL
    }
}
