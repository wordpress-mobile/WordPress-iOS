import Foundation
import AutomatticTracks

extension PrivateSiteURLProtocol {
    static func requestForPrivateAtomicSite(
        for url: URL,
        siteID: Int,
        onComplete provide: @escaping (URLRequest) -> ()) {
        
        guard !PrivateSiteURLProtocol.urlGoes(toWPComSite: url),
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let urlComponent = components.url,
            let bearerToken = bearerToken(),
            let account = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext).defaultWordPressComAccount() else {
                return provide(URLRequest(url: url))
        }
        
        let authenticationService = AtomicAuthenticationService(account: account)
        let cookieJar = HTTPCookieStorage.shared
        
        // Just in case, enforce HTTPs
        components.scheme = "https"
        
        var request = URLRequest(url: urlComponent)
        request.addValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        
        authenticationService.loadAuthCookies(into: cookieJar, username: account.username, siteID: siteID, success: {
            return provide(request)
        }) { error in
            return provide(request)
        }
        

    }
}
