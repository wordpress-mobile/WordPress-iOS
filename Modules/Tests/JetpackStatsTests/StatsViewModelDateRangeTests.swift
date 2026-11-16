import Combine
import Foundation
import Testing
@preconcurrency import WordPressKit
@testable import JetpackStats

/// `StatsViewModel` passes its date range selection to every card, and the Today
/// and top-list cards restart their load on every assignment. Assigning an
/// unchanged selection therefore throws away loads that are still in flight.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct StatsViewModelDateRangeTests {

    @Test("Finishing the first chart load does not restart the other cards' loads")
    func firstChartLoadDoesNotRestartOtherCards() async throws {
        let service = GatedStatsService()
        let viewModel = try makeViewModel(service: service)
        let chart = try #require(viewModel.cards.lazy.compactMap { $0 as? ChartCardViewModel }.first)
        let today = try #require(viewModel.cards.lazy.compactMap { $0 as? TodayCardViewModel }.first)
        let topList = try #require(viewModel.cards.lazy.compactMap { $0 as? TopListViewModel }.first)
        let selection = viewModel.dateRange

        // The cards appear and start loading. Each load sends a current-period and a
        // previous-period request, and the service holds all of them.
        today.onAppear()
        topList.onAppear()
        chart.onAppear()
        await service.today.waitUntilHeld(2)
        await service.topList.waitUntilHeld(2)
        await service.chart.waitUntilHeld(2)

        // Only the chart's requests complete.
        service.chart.open()
        await firstValue(of: chart.$isLoading) { !$0 }

        #expect(viewModel.dateRange == selection)
        #expect(service.today.cancelledCount == 0, "The Today card's in-flight load was cancelled")
        #expect(service.topList.cancelledCount == 0, "The top-list card's in-flight load was cancelled")

        // The other cards finish with the requests they started with.
        service.today.open()
        service.topList.open()
        await firstValue(of: today.$isLoading) { !$0 }
        await firstValue(of: topList.$isLoading) { !$0 }

        #expect(today.data != nil)
        #expect(service.today.requestCount == 2)
        #expect(service.topList.requestCount == 2)
    }

    @Test("Finishing a chart reload after a bar was selected does not restart the Today card's load")
    func chartReloadAfterBarSelectionDoesNotRestartTodayCard() async throws {
        let service = GatedStatsService()
        service.chart.open()
        service.today.open()
        service.topList.open()
        let viewModel = try makeViewModel(service: service)
        let chart = try #require(viewModel.cards.lazy.compactMap { $0 as? ChartCardViewModel }.first)
        let today = try #require(viewModel.cards.lazy.compactMap { $0 as? TodayCardViewModel }.first)

        today.onAppear()
        chart.onAppear()
        await firstValue(of: chart.$isLoading) { !$0 }
        await firstValue(of: today.$isLoading) { !$0 }

        // Select a bar the way `BarChartView` does. This is a real change, so the
        // Today card reloads once.
        chart.selectedBarDate = viewModel.dateRange.range.dateInterval.start
        #expect(viewModel.dateRange.subrange != nil)
        await firstValue(of: today.$isLoading) { !$0 }

        // Pick a different range. That clears the subrange, but the chart keeps its
        // bar highlight until its new data arrives. The service holds the new requests.
        service.chart.close()
        service.today.close()
        viewModel.dateRange = StatsDateRangeSelection(range: viewModel.context.calendar.makeDateRange(for: .last30Days))
        await service.chart.waitUntilHeld(2)
        await service.today.waitUntilHeld(2)
        let cancelledBefore = service.today.cancelledCount
        let selection = viewModel.dateRange

        // The chart finishes and clears its highlight.
        service.chart.open()
        await firstValue(of: chart.$isLoading) { !$0 }

        #expect(chart.selectedBarDate == nil)
        #expect(viewModel.dateRange == selection)
        #expect(service.today.cancelledCount == cancelledBefore, "The Today card's in-flight load was cancelled")

        service.today.open()
        await firstValue(of: today.$isLoading) { !$0 }
    }

    @Test("Tapping the Today card starts one Today card load")
    func todayCardTapStartsOneTodayCardLoad() async throws {
        let service = GatedStatsService()
        service.chart.open()
        service.today.open()
        service.topList.open()
        let viewModel = try makeViewModel(service: service)
        let today = try #require(viewModel.cards.lazy.compactMap { $0 as? TodayCardViewModel }.first)

        // `loadData` sets `isLoading` before it returns, so every load the tap starts
        // is counted before this test suspends.
        var loadStarts = 0
        let cancellable = today.$isLoading.dropFirst().filter { $0 }.sink { _ in loadStarts += 1 }
        defer { cancellable.cancel() }

        viewModel.handleTodayCardTap()

        #expect(viewModel.dateRange.subrange != nil)
        #expect(loadStarts == 1)
        await firstValue(of: today.$isLoading) { !$0 }
    }

    // MARK: - Helpers

    private func makeViewModel(service: GatedStatsService) throws -> StatsViewModel {
        // A fixed-offset time zone has no DST, so "today" is always 24 hours long
        // and the Today card always asks for hourly data.
        let context = StatsContext(timeZone: .eastern, siteID: 1, service: service)
        let defaults = try #require(UserDefaults(suiteName: "StatsViewModelDateRangeTests.\(UUID().uuidString)"))
        return StatsViewModel(context: context, userDefaults: defaults)
    }

    /// Suspends until `publisher` emits a value that matches `predicate`. A
    /// `@Published` publisher emits its current value first, so this returns
    /// right away when the value already matches.
    private func firstValue<P: Publisher>(
        of publisher: P,
        where predicate: @escaping (P.Output) -> Bool
    ) async where P.Failure == Never {
        var cancellable: AnyCancellable?
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            cancellable = publisher.first(where: predicate).sink { _ in continuation.resume() }
        }
        cancellable?.cancel()
    }
}

/// Sends each request to a gate. Hourly site stats come from the Today card,
/// other site stats come from the chart card.
private final class GatedStatsService: StatsServiceProtocol, @unchecked Sendable {
    let supportedMetrics: [SiteMetric] = [.views, .visitors, .likes, .comments]
    let supportedItems: [TopListItemType] = [.postsAndPages, .referrers, .locations]

    let today = RequestGate()
    let chart = RequestGate()
    let topList = RequestGate()

    func getSupportedMetrics(for item: TopListItemType) -> [SiteMetric] {
        [.views]
    }

    func getSiteStats(interval: DateInterval, granularity: DateRangeGranularity) async throws -> SiteMetricsResponse {
        try await (granularity == .hour ? today : chart).pass()
        return SiteMetricsResponse(total: SiteMetricsSet(), metrics: [:])
    }

    func getTopListData(
        _ item: TopListItemType,
        metric: SiteMetric,
        interval: DateInterval,
        granularity: DateRangeGranularity,
        limit: Int?,
        options: TopListItemOptions
    ) async throws -> TopListResponse {
        try await topList.pass()
        return TopListResponse(items: [])
    }

    // The Traffic cards in these tests do not use the methods below.
    func getWordAdsStats(date: Date, granularity: DateRangeGranularity) async throws -> WordAdsMetricsResponse {
        throw TestError.unused
    }

    func getWordAdsEarnings() async throws -> WordPressKit.StatsWordAdsEarningsResponse {
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
        // Nothing is cached.
    }

    func toggleSpamState(for referrerDomain: String, currentValue: Bool) async throws {
        throw TestError.unused
    }
}

/// Holds requests until `open()` is called, and counts the requests whose task
/// was cancelled before the gate let them through.
private final class RequestGate: @unchecked Sendable {
    private struct Waiter {
        let heldCount: Int
        let continuation: CheckedContinuation<Void, Never>
    }

    private enum Outcome {
        case pass
        case cancel
        case hold(ready: [CheckedContinuation<Void, Never>])
    }

    private let lock = NSLock()
    private var isOpen = false
    private var held: [UUID: CheckedContinuation<Void, any Error>] = [:]
    private var waiters: [Waiter] = []
    private var _requestCount = 0
    private var _cancelledCount = 0

    /// The number of requests that reached the service.
    var requestCount: Int { lock.withLock { _requestCount } }

    /// The number of requests cancelled while the gate held them.
    var cancelledCount: Int { lock.withLock { _cancelledCount } }

    func open() {
        let released: [CheckedContinuation<Void, any Error>] = lock.withLock {
            isOpen = true
            let released = Array(held.values)
            held.removeAll()
            return released
        }
        released.forEach { $0.resume() }
    }

    func close() {
        lock.withLock { isOpen = false }
    }

    /// Suspends until the gate holds at least `count` requests.
    func waitUntilHeld(_ count: Int) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let isReady: Bool = lock.withLock {
                guard held.count < count else { return true }
                waiters.append(Waiter(heldCount: count, continuation: continuation))
                return false
            }
            if isReady {
                continuation.resume()
            }
        }
    }

    func pass() async throws {
        let id = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                enter(id: id, continuation: continuation)
            }
        } onCancel: {
            let continuation: CheckedContinuation<Void, any Error>? = lock.withLock {
                guard let continuation = held.removeValue(forKey: id) else { return nil }
                _cancelledCount += 1
                return continuation
            }
            continuation?.resume(throwing: CancellationError())
        }
    }

    private func enter(id: UUID, continuation: CheckedContinuation<Void, any Error>) {
        let outcome: Outcome = lock.withLock {
            _requestCount += 1
            if isOpen {
                return .pass
            }
            // The task can be cancelled before the cancellation handler finds this request.
            if Task.isCancelled {
                _cancelledCount += 1
                return .cancel
            }
            held[id] = continuation
            let ready = waiters.filter { $0.heldCount <= held.count }
            waiters.removeAll { $0.heldCount <= held.count }
            return .hold(ready: ready.map(\.continuation))
        }
        switch outcome {
        case .pass:
            continuation.resume()
        case .cancel:
            continuation.resume(throwing: CancellationError())
        case .hold(let ready):
            ready.forEach { $0.resume() }
        }
    }
}

private enum TestError: Error {
    case unused
}
