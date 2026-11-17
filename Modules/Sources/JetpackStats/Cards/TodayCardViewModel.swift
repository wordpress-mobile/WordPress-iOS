import SwiftUI

@MainActor
final class TodayCardViewModel: ObservableObject, TrafficCardViewModel {
    var id: UUID { configuration.id }
    let cardType: CardType = .today

    @Published private(set) var configuration: TodayCardConfiguration
    @Published private(set) var data: TodayCardData?
    @Published private(set) var isLoading = true
    @Published private(set) var loadingError: Error?
    @Published var isEditing = false

    let isEditable = false

    weak var configurationDelegate: CardConfigurationDelegate?

    /// Invoked on the main actor when a load fails. An embedding host uses this
    /// to log the degraded state when no analytics tracker is installed.
    var onLoadFailure: ((any Error) -> Void)?

    var dateRange: StatsDateRangeSelection {
        didSet {
            loadData(for: dateRange.range.updating(preset: .today))
        }
    }

    private var effectiveDateRange: StatsDateRange { dateRange.range }

    var isFirstLoad: Bool { isLoading && data == nil }

    private var cachedPlaceholderData: TodayCardData?

    /// Mock data for the redacted placeholder. Kept between re-renders so the sparkline
    /// doesn't redraw with new random values, and regenerated when the hour changes.
    var placeholderData: TodayCardData {
        let currentHour = effectiveDateRange.calendar.component(.hour, from: .now)
        if let cached = cachedPlaceholderData, cached.hourlyViews.last?.hour == currentHour {
            return cached
        }
        let data = TodayCardData.placeholder(currentHour: currentHour)
        cachedPlaceholderData = data
        return data
    }

    private let service: any StatsServiceProtocol
    let tracker: (any StatsTracker)?

    private var loadingTask: Task<Void, Never>?
    private var isFirstAppear = true

    /// Clock used for staleness/rollover decisions. Injected so host-lifecycle
    /// tests can drive `refreshIfNeeded()` deterministically.
    private let currentDate: @Sendable () -> Date

    /// When the most recent load last populated `data`. Used by
    /// `refreshIfNeeded()` to decide whether the loaded data is stale.
    private var lastLoadedAt: Date?

    /// Dashboard staleness window: past this age, `refreshIfNeeded()` reloads the
    /// current period instead of trusting the in-memory data. Independent of, and
    /// deliberately longer than, the `StatsService` cache TTL, because the
    /// dashboard card's daily totals change slowly and it is revisited often.
    private static let refreshTTL: TimeInterval = 300

    init(
        configuration: TodayCardConfiguration,
        dateRange: StatsDateRange,
        context: StatsContext,
        currentDate: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.configuration = configuration
        self.dateRange = StatsDateRangeSelection(range: dateRange.updating(preset: .today))
        self.service = context.service
        self.tracker = context.tracker
        self.currentDate = currentDate
    }

    func updateConfiguration(_ newConfiguration: TodayCardConfiguration) {
        self.configuration = newConfiguration
        configurationDelegate?.saveConfiguration(for: self)
        loadData(for: effectiveDateRange)
    }

    func onAppear() {
        guard isFirstAppear else { return }
        isFirstAppear = false

        tracker?
            .send(
                .cardShown,
                properties: [
                    "card_type": CardType.today.rawValue,
                    "configuration": configuration.metrics.map(\.analyticsName).joined(separator: "_")
                ]
            )

        loadData(for: effectiveDateRange)
    }

    /// Reloads the current period when, and only when, the in-memory data can no
    /// longer be trusted: a previous load failed (retry), the day rolled over
    /// (the loaded range no longer contains the current time), or the data is
    /// older than the service cache TTL (staleness). Otherwise it is a no-op,
    /// preserving the `StatsService` cache.
    ///
    /// This is the host-controlled reload seam the dashboard drives on every
    /// appearance; the Stats screen never calls it, so its behavior is unchanged.
    func refreshIfNeeded() {
        // A load is already in flight (including the initial `onAppear` load);
        // let it finish rather than cancelling and restarting it.
        guard !isLoading else {
            return
        }

        let now = currentDate()

        // Retry after a failed or never-completed load.
        if data == nil || loadingError != nil {
            reloadCurrentPeriod()
            return
        }

        // Midnight rollover: the loaded range no longer contains "now".
        if !effectiveDateRange.dateInterval.contains(now) {
            reloadCurrentPeriod()
            return
        }

        // Staleness: the loaded data is older than the service cache TTL.
        if let lastLoadedAt, now.timeIntervalSince(lastLoadedAt) >= Self.refreshTTL {
            reloadCurrentPeriod()
            return
        }
    }

    /// Cancels any in-flight load. Used when the host is torn down (for example
    /// a site switch) so a stale response cannot land on the wrong site.
    func cancelLoading() {
        loadingTask?.cancel()
        loadingTask = nil
        // The cancelled task returns before its own `isLoading = false` reset
        // runs, so reset it here; otherwise `refreshIfNeeded()`'s in-flight
        // guard would treat the abandoned load as still running forever.
        isLoading = false
    }

    /// Recomputes the `.today` range against the current date (rolling it over
    /// when needed) and reloads. Assigning `dateRange` triggers its `didSet`,
    /// which drives the load through the existing path.
    private func reloadCurrentPeriod() {
        dateRange = StatsDateRangeSelection(range: dateRange.range.updating(preset: .today))
    }

    private func loadData(for dateRange: StatsDateRange) {
        loadingTask?.cancel()

        // Reflect the in-flight state synchronously so a load scheduled here is
        // observable immediately (the async task below also sets it, but not
        // until it starts running). This keeps `refreshIfNeeded()`'s
        // `isLoading` guard correct between back-to-back reloads.
        isLoading = true

        // Create a new loading task
        loadingTask = Task { [weak self] in
            guard let self else { return }
            await self.actuallyLoadData(dateRange: dateRange)
        }
    }

    private func actuallyLoadData(dateRange: StatsDateRange) async {
        isLoading = true
        loadingError = nil

        do {
            let loadedData = try await getSiteStats(dateRange: dateRange)

            try Task.checkCancellation()

            data = loadedData
            lastLoadedAt = currentDate()
        } catch is CancellationError {
            return
        } catch {
            loadingError = error
            tracker?.trackError(error, screen: "today_card")
            onLoadFailure?(error)
        }

        isLoading = false
    }

    private func getSiteStats(dateRange: StatsDateRange) async throws -> TodayCardData {
        let granularity = dateRange.dateInterval.preferredGranularity

        async let currentResponseTask = service.getSiteStats(
            interval: dateRange.dateInterval,
            granularity: granularity
        )
        async let previousResponseTask = service.getSiteStats(
            interval: dateRange.effectiveComparisonInterval,
            granularity: granularity
        )

        let currentResponse = try await currentResponseTask
        let previousResponse = try? await previousResponseTask

        // Extract hourly views data and convert to simple tuples
        let calendar = dateRange.calendar
        let hourlyViews = (currentResponse.metrics[.views] ?? [])
            .map { dataPoint in
                (hour: calendar.component(.hour, from: dataPoint.date), value: dataPoint.value)
            }
        let previousHourlyViews = previousResponse?.metrics[.views]?
            .map { dataPoint in
                (hour: calendar.component(.hour, from: dataPoint.date), value: dataPoint.value)
            }

        var metricsSet = SiteMetricsSet()
        for metric in configuration.metrics {
            metricsSet[metric] = currentResponse.total[metric]
        }

        return TodayCardData(
            hourlyViews: hourlyViews,
            previousHourlyViews: previousHourlyViews,
            metrics: metricsSet
        )
    }
}

struct TodayCardData {
    let id = UUID()
    let hourlyViews: [(hour: Int, value: Int)]
    let previousHourlyViews: [(hour: Int, value: Int)]?
    let metrics: SiteMetricsSet
}

extension TodayCardData {
    /// Mock data shaped like loaded data: today's series ends at the current hour
    /// (``StatsService`` filters out future dates) and the previous day's covers all 24 hours.
    static func placeholder(currentHour: Int) -> TodayCardData {
        // Generate hourly data points with a realistic curve peaking mid-day
        let hourlyViews = (0...currentHour)
            .map { hour in
                let normalizedHour = Double(hour)
                // Create a bell curve centered around hour 14 (2 PM)
                let peakHour = 14.0
                let spread = 4.5 // Reduced spread for sharper peak
                let amplitude = 300.0 // Increased amplitude for higher peak
                let baseline = 20.0 // Lower baseline to increase contrast

                let bellCurve = amplitude * exp(-pow(normalizedHour - peakHour, 2) / (2 * pow(spread, 2))) + baseline
                let noise = Double.random(in: -30...30)
                let value = Int(bellCurve + noise)

                return (hour: hour, value: max(15, value))
            }

        let previousHourlyViews = (0..<24)
            .map { hour in
                let normalizedHour = Double(hour)
                // Similar curve but slightly different for comparison
                let peakHour = 12.0
                let spread = 3.0 // Reduced spread for sharper peak
                let amplitude = 280.0 // Increased amplitude for higher peak
                let baseline = 18.0 // Lower baseline to increase contrast

                let bellCurve = amplitude * exp(-pow(normalizedHour - peakHour, 2) / (2 * pow(spread, 2))) + baseline
                let noise = Double.random(in: -30...30)
                let value = Int(bellCurve + noise)

                return (hour: hour, value: max(12, value))
            }

        var metricsSet = SiteMetricsSet()
        metricsSet[.views] = 1234
        metricsSet[.visitors] = 567
        metricsSet[.likes] = 89
        metricsSet[.comments] = 12

        return TodayCardData(
            hourlyViews: hourlyViews,
            previousHourlyViews: previousHourlyViews,
            metrics: metricsSet
        )
    }
}
