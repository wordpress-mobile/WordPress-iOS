import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import Testing
import UIKit
@testable import WordPress

@MainActor
@Suite(.serialized)
struct SiteDesignContentCollectionViewControllerTests {
    @Test func comingBackBeforeTheDesignsLoadDoesNotStartASecondRequest() async throws {
        let requests = RequestCounter()
        let stub = HTTPStubs.stubRequests(
            passingTest: { $0.url?.path.hasSuffix("/common-starter-site-designs") == true },
            withStubResponse: { _ in
                requests.increment()
                // A slow connection: the response arrives long after the test has finished checking.
                return HTTPStubsResponse(jsonObject: ["designs": [], "categories": []], statusCode: 200, headers: nil)
                    .responseTime(5)
            }
        )
        defer { HTTPStubs.removeStub(stub) }

        let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        let designStep = SiteDesignContentCollectionViewController(creator: SiteCreator(), createsSite: true) { _ in }
        let navigation = UINavigationController(rootViewController: designStep)
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        // The design step appears and requests the designs.
        try await waitUntil { requests.value >= 1 }
        #expect(requests.value == 1)

        // Before they load, the user moves on to the next step, then comes back.
        navigation.pushViewController(UIViewController(), animated: false)
        window.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(300))
        navigation.popViewController(animated: false)
        window.layoutIfNeeded()
        try await Task.sleep(for: .seconds(1))

        #expect(requests.value == 1, "design requests started: \(requests.value)")
    }

    private func waitUntil(timeout: Duration = .seconds(5), _ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + timeout
        while !condition() && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(50))
        }
    }
}

private final class RequestCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int { lock.withLock { count } }

    func increment() { lock.withLock { count += 1 } }
}
