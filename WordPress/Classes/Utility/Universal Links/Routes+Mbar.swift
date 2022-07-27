import Foundation
import Alamofire

/// Handles mbar redirects.  These are marketing redirects to URLs that mobile should handle.
///
/// - Important: Mbar redirects are supposed to always have a destination URL that can be handled
///     by the App.  If the final URL can't be handled by the App, then it should not really be an
///     /mbar redirect to begin with, but a /bar redirect.  In this case, the link in the marketing
///     email should be fixed.
///     That said, if for any reason the final URL can't be really handled by the App, the user will
///     be sent back to the default browser.  Such a case isn't great in terms of UX because the App
///     will be opened and then the default browser will be opened... but other than that, it is
///     a safe procedure.
///
///     Many mbar links will consist of an initial redirect_to value of wp-login.php, which in turn
///     has its own redirect_to parameter containing our final destination. For these links, we'll
///     keep following the redirects until we find the end point.
///
///   * /mbar/?redirect_to=https%3A%2F%2Fwordpress.com%2Fpost%2Fsomesite.wordpress.com
///
public struct MbarRoute: Route {
    private static let redirectURLParameter = "redirect_to"
    private static let campaignURLParameter = "login_reason"
    private static let unknownCampaignValue = "unknown"
    private static let loginURLPath = "wp-login.php"

    let path = "/mbar"

    let section: DeepLinkSection? = nil

    var action: NavigationAction {
        return self
    }

    let shouldTrack: Bool = false

    private func redirectURL(from url: String) -> URL? {
        guard let components = URLComponents(string: url) else {
            return nil
        }

        return redirectURL(from: components)
    }

    private func redirectURL(from components: URLComponents, followRedirects: Bool = true) -> URL? {
        guard let redirectURL = components.queryItems?.first(where: { $0.name == MbarRoute.redirectURLParameter })?.value?.removingPercentEncoding else {
            return nil
        }

        let url = URL(string: redirectURL)

        // If this is a wp-login link, handle _its_ redirect_to parameter
        if followRedirects && url?.lastPathComponent == MbarRoute.loginURLPath {
            return self.redirectURL(from: redirectURL)
        }

        return url
    }

    private func campaign(from url: String) -> String {
        guard let components = URLComponents(string: url),
              let url = redirectURL(from: components, followRedirects: false),
              let redirectComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let campaignValue = redirectComponents.queryItems?.first(where: { $0.name == MbarRoute.campaignURLParameter })?.value?.removingPercentEncoding else {
            return MbarRoute.unknownCampaignValue
        }

        return campaignValue
    }
}

extension MbarRoute: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController? = nil, router: LinkRouter) {

        guard let url = values[MatchedRouteURLComponentKey.url.rawValue],
            let redirectUrl = redirectURL(from: url) else {
                failAndBounce(values)
                return
        }

        // If we're handling the link in the app, fire off a request to the
        // original URL so that any necessary tracking takes places.
        Alamofire.request(url)
            .validate()
            .responseData { response in
                switch response.result {
                case .success:
                    DDLogInfo("Mbar deep link request successful.")
                case .failure(let error):
                    DDLogError("Mbar deep link request failed: \(error.localizedDescription)")
                }
            }

        router.handle(url: redirectUrl, shouldTrack: true, source: .email(campaign: campaign(from: url)))
    }
}
