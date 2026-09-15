import Foundation
import Testing
@testable import WordPressComments

// The Fetcher closure is @Sendable, so tests can't mutate captured locals
// from inside it under Swift 6; an actor records the calls instead.
actor FetchLog {
    private(set) var batches: [[Int64]] = []
    func record(_ ids: [Int64]) {
        batches.append(ids.sorted())
    }
}

@MainActor
struct PostTitleResolverTests {
    @Test func resolvesTitlesAndCaches() async {
        let log = FetchLog()
        let resolver = PostTitleResolver { ids in
            await log.record(ids)
            return PostTitleResolver.FetchResult(
                titles: Dictionary(uniqueKeysWithValues: ids.map { ($0, "Title \($0)") })
            )
        }

        await resolver.resolveAndWait(ids: [1, 2])
        await resolver.resolveAndWait(ids: [2, 3]) // 2 already resolved

        #expect(resolver.titleState(for: 1) == .resolved("Title 1"))
        #expect(resolver.titleState(for: 3) == .resolved("Title 3"))
        #expect(await log.batches == [[1, 2], [3]])
    }

    @Test func alreadyResolvedSetFetchesNothing() async {
        let log = FetchLog()
        let resolver = PostTitleResolver { ids in
            await log.record(ids)
            return PostTitleResolver.FetchResult(
                titles: Dictionary(uniqueKeysWithValues: ids.map { ($0, "T") })
            )
        }

        await resolver.resolveAndWait(ids: [1])
        await resolver.resolveAndWait(ids: [1])

        #expect(await log.batches.count == 1)
    }

    @Test func missingIDsBecomeUnavailableAndAreNotRefetched() async {
        let log = FetchLog()
        let resolver = PostTitleResolver { ids in
            await log.record(ids)
            return PostTitleResolver.FetchResult(titles: [:]) // found, nothing matched
        }

        await resolver.resolveAndWait(ids: [7])
        await resolver.resolveAndWait(ids: [7])

        #expect(resolver.titleState(for: 7) == .unavailable)
        #expect(await log.batches == [[7]])
    }

    @Test func fetchFailureShowsUnavailableButRetriesNextTime() async {
        let log = FetchLog()
        let resolver = PostTitleResolver { ids in
            await log.record(ids)
            if await log.batches.count == 1 { throw FakeServiceError() }
            return PostTitleResolver.FetchResult(
                titles: Dictionary(uniqueKeysWithValues: ids.map { ($0, "Recovered") })
            )
        }

        await resolver.resolveAndWait(ids: [5])
        #expect(resolver.titleState(for: 5) == .unavailable)

        await resolver.resolveAndWait(ids: [5])
        #expect(resolver.titleState(for: 5) == .resolved("Recovered"))
    }

    @Test func partialFailureKeepsResolvedTitlesAndRetriesRemainder() async {
        let log = FetchLog()
        let resolver = PostTitleResolver { ids in
            await log.record(ids)
            // First batch resolves id 1 but reports id 2 as retryable (its pages
            // lookup failed); the retry then resolves id 2.
            if await log.batches.count == 1 {
                return PostTitleResolver.FetchResult(titles: [1: "Post One"], retryable: [2])
            }
            return PostTitleResolver.FetchResult(titles: [2: "Page Two"])
        }

        await resolver.resolveAndWait(ids: [1, 2])
        #expect(resolver.titleState(for: 1) == .resolved("Post One"))
        #expect(resolver.titleState(for: 2) == .unavailable)

        await resolver.resolveAndWait(ids: [1, 2])
        // id 1 stays resolved and is not refetched; only id 2 is retried.
        #expect(resolver.titleState(for: 1) == .resolved("Post One"))
        #expect(resolver.titleState(for: 2) == .resolved("Page Two"))
        #expect(await log.batches == [[1, 2], [2]])
    }

    @Test func cacheHitSkipsNetworkLookup() async throws {
        let cacheLog = FetchLog()
        let networkLog = FetchLog()
        let fetcher = PostTitleResolver.cacheFirstFetcher(
            cache: { ids in
                await cacheLog.record(ids)
                return .init(titles: [1: "Cached title"])
            },
            network: { ids in
                await networkLog.record(ids)
                return .init(titles: [:])
            }
        )

        let result = try await fetcher([1])

        #expect(result.titles == [1: "Cached title"])
        #expect(await cacheLog.batches == [[1]])
        #expect(await networkLog.batches.isEmpty)
    }

    @Test func cacheMissFetchesOnlyUnresolvedIDs() async throws {
        let networkLog = FetchLog()
        let fetcher = PostTitleResolver.cacheFirstFetcher(
            cache: { _ in .init(titles: [1: "Cached title"]) },
            network: { ids in
                await networkLog.record(ids)
                return .init(titles: [2: "Network title"])
            }
        )

        let result = try await fetcher([1, 2])

        #expect(result.titles == [1: "Cached title", 2: "Network title"])
        #expect(await networkLog.batches == [[2]])
    }

    @Test func cacheFailureFallsBackToNetwork() async throws {
        let networkLog = FetchLog()
        let fetcher = PostTitleResolver.cacheFirstFetcher(
            cache: { _ in throw FakeServiceError() },
            network: { ids in
                await networkLog.record(ids)
                return .init(titles: [1: "Network title"])
            }
        )

        let result = try await fetcher([1])

        #expect(result.titles == [1: "Network title"])
        #expect(await networkLog.batches == [[1]])
    }

    @Test func networkFailureKeepsCachedTitlesAndRetriesOnlyUnresolvedIDs() async throws {
        let fetcher = PostTitleResolver.cacheFirstFetcher(
            cache: { _ in .init(titles: [1: "Cached title"]) },
            network: { _ in throw FakeServiceError() }
        )

        let result = try await fetcher([1, 2])

        #expect(result.titles == [1: "Cached title"])
        #expect(result.retryable == [2])
    }

    @Test func normalizesRenderedTitles() {
        #expect(PostTitleResolver.normalizedTitle(" <p>Post <strong>title</strong></p> ") == "Post title")
        #expect(PostTitleResolver.normalizedTitle("<p> </p>") == nil)
    }

    @Test func unknownIDReportsLoading() {
        let resolver = PostTitleResolver { _ in PostTitleResolver.FetchResult(titles: [:]) }
        #expect(resolver.titleState(for: 99) == .loading)
    }
}
