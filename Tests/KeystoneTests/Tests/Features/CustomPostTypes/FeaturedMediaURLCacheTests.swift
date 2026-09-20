import Foundation
import Testing
import WordPressAPI
import WordPressAPIInternal

@testable import WordPress

@Suite("FeaturedMediaURLCache")
@MainActor
struct FeaturedMediaURLCacheTests {
    /// Answers with whatever `urls` holds at the moment of the call, so a test
    /// can make a lookup fail and then succeed on the retry. Called from
    /// concurrent tasks, so it locks around its bookkeeping.
    private final class Resolver: @unchecked Sendable {
        private let lock = NSLock()
        private var _urls: [MediaId: URL] = [:]
        private var _requested: [MediaId] = []

        var urls: [MediaId: URL] {
            get { lock.withLock { _urls } }
            set { lock.withLock { _urls = newValue } }
        }

        var requested: [MediaId] {
            lock.withLock { _requested }
        }

        @MainActor func cache() -> FeaturedMediaURLCache {
            FeaturedMediaURLCache { mediaId in
                let url = self.lock.withLock {
                    self._requested.append(mediaId)
                    return self._urls[mediaId]
                }
                guard let url else { throw URLError(.badServerResponse) }
                return url
            }
        }
    }

    private let url = URL(string: "https://example.com/image.jpg")!

    @Test("an id nobody has asked about yet reads as pending")
    func unknownIsPending() {
        let cache = Resolver().cache()
        #expect(cache.entry(for: 1).state == .pending)
    }

    @Test("an id the API cannot have is unresolvable without a request")
    func zeroIsUnresolvable() async {
        let resolver = Resolver()
        let cache = resolver.cache()

        cache.mediaDidAppear(0)
        await cache.awaitInFlightResolutions()
        cache.retryFailures()
        await cache.awaitInFlightResolutions()

        #expect(cache.entry(for: 0).state == .unresolvable)
        #expect(resolver.requested.isEmpty)
    }

    @Test("a successful lookup resolves, and is not asked for twice")
    func resolves() async {
        let resolver = Resolver()
        resolver.urls = [1: url]
        let cache = resolver.cache()

        cache.mediaDidAppear(1)
        await cache.awaitInFlightResolutions()
        cache.mediaDidAppear(1)
        await cache.awaitInFlightResolutions()

        #expect(cache.entry(for: 1).state == .resolved(url))
        #expect(resolver.requested == [1])
    }

    @Test("a failed lookup is unresolvable rather than stuck pending")
    func fails() async {
        let cache = Resolver().cache()

        cache.mediaDidAppear(1)
        await cache.awaitInFlightResolutions()

        #expect(cache.entry(for: 1).state == .unresolvable)
    }

    @Test("retrying re-asks for the failures on screen, and only for those")
    func retryFailures() async {
        let resolver = Resolver()
        resolver.urls = [2: url]
        let cache = resolver.cache()

        cache.mediaDidAppear(1)
        cache.mediaDidAppear(2)
        await cache.awaitInFlightResolutions()
        #expect(cache.entry(for: 1).state == .unresolvable)
        #expect(cache.entry(for: 2).state == .resolved(url))

        resolver.urls[1] = url
        cache.retryFailures()
        await cache.awaitInFlightResolutions()

        #expect(cache.entry(for: 1).state == .resolved(url))
        #expect(resolver.requested.sorted() == [1, 1, 2])
    }

    @Test("a retry that fails again leaves the row where it was")
    func retryFailsAgain() async {
        let resolver = Resolver()
        let cache = resolver.cache()

        cache.mediaDidAppear(1)
        await cache.awaitInFlightResolutions()
        cache.retryFailures()
        await cache.awaitInFlightResolutions()

        #expect(cache.entry(for: 1).state == .unresolvable)
        #expect(resolver.requested == [1, 1])
    }

    @Test("a failure that has scrolled off screen waits until it reappears")
    func retryOffScreen() async {
        let resolver = Resolver()
        let cache = resolver.cache()

        cache.mediaDidAppear(1)
        await cache.awaitInFlightResolutions()
        cache.mediaDidDisappear(1)

        cache.retryFailures()
        await cache.awaitInFlightResolutions()
        #expect(cache.entry(for: 1).state == .pending)
        #expect(resolver.requested == [1])

        resolver.urls[1] = url
        cache.mediaDidAppear(1)
        await cache.awaitInFlightResolutions()
        #expect(cache.entry(for: 1).state == .resolved(url))
    }
}
