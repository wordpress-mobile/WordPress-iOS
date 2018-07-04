import XCTest
@testable import WordPress

private struct TestRoute: Route {
    let path: String
    let action: NavigationAction = TestAction()
}

private struct TestAction: NavigationAction {
    func perform() {}
}

class RouteMatcherTests: XCTestCase {

    var matcher: RouteMatcher!
    var routes: [Route]!

    func testNoMatchingRoutes() {
        routes = [ TestRoute(path: "/me") ]
        matcher = RouteMatcher(routes: routes)

        let matches = matcher.routesMatching("/hello")
        XCTAssert(matches.count == 0)
    }

    func testMatchingRouteWithSingleComponent() {
        routes = [ TestRoute(path: "/me"), TestRoute(path: "/me/account") ]
        matcher = RouteMatcher(routes: routes)

        let matches = matcher.routesMatching("/me") as [Route]
        XCTAssert(matches.first!.isEqual(to: routes.first!))
        XCTAssert(matches.count == 1)
    }

    func testMatchingRouteWithManyComponents() {
        routes = [ TestRoute(path: "/me"), TestRoute(path: "/me/account") ]
        matcher = RouteMatcher(routes: routes)

        let matches = matcher.routesMatching("/me/account") as [Route]
        XCTAssert(matches.first!.isEqual(to: routes.last!))
        XCTAssert(matches.count == 1)
    }

    func testMultipleMatchingRoutes() {
        routes = [ TestRoute(path: "/me"), TestRoute(path: "/me") ]
        matcher = RouteMatcher(routes: routes)

        let matches = matcher.routesMatching("/me") as [Route]
        XCTAssert(matches.elementsEqual(routes, by: { $0.isEqual(to: $1) }))
    }

    func testMatchingRouteWithSingleFinalPlaceholder() {
        routes = [ TestRoute(path: "/me/:placeholder") ]
        matcher = RouteMatcher(routes: routes)

        let matches = matcher.routesMatching("/me/hello") as [Route]
        XCTAssert(matches.first!.isEqual(to: routes.first!))
        XCTAssert(matches.count == 1)
    }

    // MARK: - Placeholders

    func testMatchedRouteWithSinglePlaceholdersHasPopulatedValue() {
        routes = [ TestRoute(path: "/me/:account") ]
        matcher = RouteMatcher(routes: routes)

        let matches = matcher.routesMatching("/me/bobsmith")
        let values = matches.first!.values
        XCTAssert(values.count == 1)
        XCTAssertEqual(values["account"], "bobsmith")
    }

    func testMatchedRouteWithNoPlaceholdersHasNoValues() {
        routes = [ TestRoute(path: "/me") ]
        matcher = RouteMatcher(routes: routes)

        let matches = matcher.routesMatching("/me")
        XCTAssert(matches.first!.values.count == 0)
    }

    func testLongerRouteDoesntMatchPartial() {
        routes = [ TestRoute(path: "/me/:account/share/:type") ]
        matcher = RouteMatcher(routes: routes)

        let matches = matcher.routesMatching("/me/bobsmith")
        XCTAssert(matches.count == 0)
    }

    func testMatchedRouteWithManyPlaceholders() {
        routes = [ TestRoute(path: "/me/:account/share/:type") ]
        matcher = RouteMatcher(routes: routes)

        let matches = matcher.routesMatching("/me/bobsmith/share/group")
        let values = matches.first!.values
        XCTAssert(values.count == 2)
        XCTAssertEqual(values["account"], "bobsmith")
        XCTAssertEqual(values["type"], "group")
    }

    func testMultipleMatchedRouteWithManyPlaceholders() {
        routes = [ TestRoute(path: "/me/:account/share/:type"),
                   TestRoute(path: "/me/:account/share/"),
                   TestRoute(path: "/me/:account/share/:test") ]
        matcher = RouteMatcher(routes: routes)

        let matches = matcher.routesMatching("/me/bobsmith/share/group")
        XCTAssert(matches.count == 2)

        let values1 = matches.first!.values
        XCTAssert(values1.count == 2)

        let values2 = matches.last!.values
        XCTAssert(values2.count == 2)

        XCTAssertEqual(values1["account"], "bobsmith")
        XCTAssertEqual(values1["type"], "group")
        XCTAssertEqual(values2["account"], "bobsmith")
        XCTAssertEqual(values2["test"], "group")
    }
}
