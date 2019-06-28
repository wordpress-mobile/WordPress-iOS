import Foundation


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
///   * /mbar/?redirect_to=https%3A%2F%2Fwordpress.com%2Fpost%2Fsomesite.wordpress.com
///
struct MbarRoute: Route {
    static let redirectURLParameter = "redirect_to"
    let path = "/mbar"

    var action: NavigationAction {
        return self
    }

    private func redirectURL(from url: String) -> URL? {
        guard let components = URLComponents(string: url) else {
            return nil
        }

        return redirectURL(from: components)
    }

    private func redirectURL(from components: URLComponents) -> URL? {
        guard let redirectURL = components.queryItems?.first(where: { $0.name == MbarRoute.redirectURLParameter })?.value?.removingPercentEncoding else {
            return nil
        }

        return URL(string: redirectURL)
    }
}

extension MbarRoute: NavigationAction {
    func perform(_ values: [String: String], source: UIViewController? = nil) {

        guard let url = values[MatchedRouteURLComponentKey.url.rawValue],
            let redirectUrl = redirectURL(from: url) else {
                failAndBounce(values)
                return
        }

        UniversalLinkRouter.shared.handle(url: redirectUrl, shouldTrack: false, source: source)
    }
}
