import Foundation
import WordPressAPI
import WordPressAPIInternal

public final class WordPressClient: Sendable {
    public let siteURL: URL
    public let api: WordPressAPI
    public let cache: WordPressApiCache?
    public let service: WpSelfHostedService?

    public convenience init(
        urlSession: URLSession,
        siteURL: URL,
        apiUrlResolver: ApiUrlResolver,
        authenticationProvider: WpAuthenticationProvider,
        middlewarePipeline: MiddlewarePipeline = .default,
        appNotifier: WpAppNotifier? = nil,
    ) {
        assert(apiUrlResolver is WpOrgSiteApiUrlResolver || apiUrlResolver is WpComDotOrgApiUrlResolver)

        let api = WordPressAPI(
            urlSession: urlSession,
            apiUrlResolver: apiUrlResolver,
            authenticationProvider: authenticationProvider,
            appNotifier: appNotifier
        )

        let cache = WordPressApiCache.bootstrap()
        cache?.startListeningForUpdates()

        let service: WpSelfHostedService?
        if let cache, let resolver = apiUrlResolver as? WpOrgSiteApiUrlResolver {
            service = try? WpSelfHostedService(
                siteUrl: siteURL.absoluteString,
                apiRoot: resolver.apiRootUrl().url(),
                apiUrlResolver: apiUrlResolver,
                delegate: api.apiClientDelegate,
                cache: cache.cache
            )
        } else {
            service = nil
        }

        self.init(api: api, cache: cache, service: service, siteURL: siteURL)
    }

    public init(api: WordPressAPI, cache: WordPressApiCache?, service: WpSelfHostedService?, siteURL: URL) {
        self.api = api
        self.cache = cache
        self.service = service
        self.siteURL = siteURL
    }
}
