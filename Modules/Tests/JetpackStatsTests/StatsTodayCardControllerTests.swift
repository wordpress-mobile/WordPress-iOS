import Foundation
import Testing
@preconcurrency import WordPressKit
@testable import JetpackStats

/// Covers the controller-driven lifecycle the My Site dashboard relies on:
/// `refreshIfNeeded()` retry/staleness/rollover/no-op decisions and `cancel()`.
@MainActor
@Suite
struct StatsTodayCardControllerTests {

    @Test("refreshIfNeeded retries after a failed load")
    func retriesAfterFailure() async {
        let service = ControllableStatsService()
        await service.setShouldFail(true)
        let vm = Self.makeViewModel(service: service)

        vm.onAppear()
        await Self.waitUntilIdle(vm)

        #expect(vm.data == nil)
        #expect(vm.loadingError != nil)
        let countAfterFailure = await service.loadCount

        await service.setShouldFail(false)
        vm.refreshIfNeeded()
        await Self.waitUntilIdle(vm)

        #expect(vm.data != nil)
        #expect(vm.loadingError == nil)
        #expect(await service.loadCount > countAfterFailure)
    }

    @Test("refreshIfNeeded reloads when the data is older than the refresh window")
    func reloadsWhenStale() async {
        let clock = Clock()
        let service = ControllableStatsService()
        let vm = Self.makeViewModel(service: service, clock: clock)

        vm.onAppear()
        await Self.waitUntilIdle(vm)
        #expect(vm.data != nil)
        let count = await service.loadCount

        // Past the 300s refresh window.
        clock.now = clock.now.addingTimeInterval(301)
        vm.refreshIfNeeded()
        await Self.waitUntilIdle(vm)

        #expect(await service.loadCount > count)
    }

    @Test("refreshIfNeeded is a no-op when the data is still fresh")
    func noOpWhenFresh() async {
        let clock = Clock()
        let service = ControllableStatsService()
        let vm = Self.makeViewModel(service: service, clock: clock)

        vm.onAppear()
        await Self.waitUntilIdle(vm)
        #expect(vm.data != nil)
        let count = await service.loadCount

        // Within the TTL, same day.
        clock.now = clock.now.addingTimeInterval(5)
        vm.refreshIfNeeded()
        await Task.yield()

        #expect(await service.loadCount == count)
    }

    @Test("refreshIfNeeded reloads after the day rolls over")
    func reloadsAfterRollover() async {
        let clock = Clock()
        let service = ControllableStatsService()
        let vm = Self.makeViewModel(service: service, clock: clock)

        vm.onAppear()
        await Self.waitUntilIdle(vm)
        #expect(vm.data != nil)
        let count = await service.loadCount

        // Two days later: the loaded range no longer contains "now".
        clock.now = clock.now.addingTimeInterval(2 * 24 * 60 * 60)
        vm.refreshIfNeeded()
        await Self.waitUntilIdle(vm)

        #expect(await service.loadCount > count)
    }

    @Test("cancel cancels an in-flight load")
    func cancelCancelsInFlightLoad() async {
        let service = ControllableStatsService()
        await service.setHoldLoads(true)
        let vm = Self.makeViewModel(service: service)

        vm.onAppear()
        // Let the load enter the (held) service call.
        try? await Task.sleep(for: .milliseconds(30))
        #expect(vm.isLoading)
        #expect(vm.data == nil)

        vm.cancelLoading()
        try? await Task.sleep(for: .milliseconds(40))

        // A cancelled load neither populates data nor surfaces an error.
        #expect(vm.data == nil)
        #expect(vm.loadingError == nil)
    }

    @Test("refreshIfNeeded reloads after a cancelled load")
    func refreshesAfterCancelledLoad() async {
        let service = ControllableStatsService()
        await service.setHoldLoads(true)
        let vm = Self.makeViewModel(service: service)

        vm.onAppear()
        // Let the load enter the (held) service call, then abandon it.
        try? await Task.sleep(for: .milliseconds(30))
        vm.cancelLoading()
        try? await Task.sleep(for: .milliseconds(40))

        // The abandoned load must not be mistaken for an in-flight one.
        #expect(!vm.isLoading)

        await service.setHoldLoads(false)
        let count = await service.loadCount
        vm.refreshIfNeeded()
        await Self.waitUntilIdle(vm)

        #expect(vm.data != nil)
        #expect(await service.loadCount > count)
    }

    @Test("the controller forwards refresh and reports load failures")
    func controllerForwardsRefreshAndReportsFailures() async {
        let service = ControllableStatsService()
        await service.setShouldFail(true)
        let context = StatsContext(timeZone: .current, siteID: 1, service: service)
        let controller = StatsTodayCardController(context: context)

        var reportedError: (any Error)?
        controller.onLoadError = { reportedError = $0 }

        controller.viewModel.onAppear()
        await Self.waitUntilIdle(controller.viewModel)

        #expect(controller.viewModel.data == nil)
        #expect(reportedError != nil)

        await service.setShouldFail(false)
        let count = await service.loadCount
        controller.refreshIfNeeded()
        await Self.waitUntilIdle(controller.viewModel)

        #expect(controller.viewModel.data != nil)
        #expect(await service.loadCount > count)
    }

    // MARK: - Helpers

    private static func makeViewModel(
        service: ControllableStatsService,
        clock: Clock = Clock()
    ) -> TodayCardViewModel {
        let context = StatsContext(timeZone: .current, siteID: 1, service: service)
        return TodayCardViewModel(
            configuration: TodayCardConfiguration(metrics: [.views, .visitors]),
            dateRange: context.calendar.makeDateRange(for: .today),
            context: context,
            currentDate: { clock.now }
        )
    }

    private static func waitUntilIdle(_ viewModel: TodayCardViewModel) async {
        for _ in 0..<500 {
            if !viewModel.isLoading {
                return
            }
            try? await Task.sleep(for: .milliseconds(2))
        }
    }
}

/// A settable clock so staleness and rollover decisions are deterministic.
private final class Clock: @unchecked Sendable {
    private let lock = NSLock()
    private var _now: Date

    init(_ now: Date = Date()) {
        _now = now
    }

    var now: Date {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _now
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _now = newValue
        }
    }
}

/// A `StatsServiceProtocol` stub whose `getSiteStats` can fail, be held in-flight
/// (to test cancellation), and reports how many times it was called.
private actor ControllableStatsService: StatsServiceProtocol {
    nonisolated let supportedMetrics: [SiteMetric] = [.views, .visitors, .likes, .comments]
    nonisolated let supportedItems: [TopListItemType] = []

    nonisolated func getSupportedMetrics(for item: TopListItemType) -> [SiteMetric] {
        [.views]
    }

    private(set) var loadCount = 0
    private var shouldFail = false
    private var holdLoads = false

    func setShouldFail(_ value: Bool) {
        shouldFail = value
    }

    func setHoldLoads(_ value: Bool) {
        holdLoads = value
    }

    func getSiteStats(interval: DateInterval, granularity: DateRangeGranularity) async throws -> SiteMetricsResponse {
        loadCount += 1

        if holdLoads {
            // Hang until the enclosing task is cancelled.
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(5))
            }
            throw CancellationError()
        }

        if shouldFail {
            throw TestError.load
        }

        return SiteMetricsResponse(total: SiteMetricsSet(), metrics: [:])
    }

    // The Today card does not use the methods below.
    func getWordAdsStats(date: Date, granularity: DateRangeGranularity) async throws -> WordAdsMetricsResponse {
        throw TestError.unused
    }

    func getWordAdsEarnings() async throws -> WordPressKit.StatsWordAdsEarningsResponse {
        throw TestError.unused
    }

    func getTopListData(_ item: TopListItemType, metric: SiteMetric, interval: DateInterval, granularity: DateRangeGranularity, limit: Int?, options: TopListItemOptions) async throws -> TopListResponse {
        throw TestError.unused
    }

    func getRealtimeTopListData(_ item: TopListItemType) async throws -> TopListResponse {
        throw TestError.unused
    }

    func getPostDetails(for postID: Int) async throws -> StatsPostDetails {
        throw TestError.unused
    }

    func getPostLikes(for postID: Int, count: Int) async throws -> PostLikesData {
        throw TestError.unused
    }

    func getEmailOpens(for postID: Int) async throws -> StatsEmailOpensData {
        throw TestError.unused
    }

    func invalidateTopListData(for item: TopListItemType) async {
        // No-op; the Today card does not use top-list data.
    }

    func toggleSpamState(for referrerDomain: String, currentValue: Bool) async throws {
        throw TestError.unused
    }
}

private enum TestError: Error {
    case load
    case unused
}
