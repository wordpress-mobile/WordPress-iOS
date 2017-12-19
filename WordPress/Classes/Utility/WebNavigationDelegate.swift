import Foundation
import WebKit

// This is an odd design, but it needs to work on Objective-C
// Since Swift now allows ommiting the type in static functions, it will
// look like an enum on the delegate implementations:
//
// func shouldNavigate(request: URLRequest) -> WebNavigationPolicy {
//   return .allow
//   return .cancel
//   return .redirect(request)
// }
class WebNavigationPolicy: NSObject {
    @objc private(set) var redirectRequest: URLRequest?
    @objc private(set) var action: WKNavigationActionPolicy = .cancel

    private override init() {}

    @objc static let allow: WebNavigationPolicy = {
        let policy = WebNavigationPolicy()
        policy.action = .allow
        return policy
    }()

    @objc static let cancel = WebNavigationPolicy()

    @objc static func redirect(_ request: URLRequest) -> WebNavigationPolicy {
        let policy = WebNavigationPolicy()
        policy.redirectRequest = request
        return policy
    }
}

@objc
protocol WebNavigationDelegate {
    func shouldNavigate(request: URLRequest) -> WebNavigationPolicy
}
