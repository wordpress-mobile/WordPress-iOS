import Foundation
import Testing
@testable import JetpackStats

@Suite @MainActor
struct ChartCardViewModelTests {
    @Test("Selecting a chart type updates the selection and tracks the change")
    func selectChartType() throws {
        let tracker = RecordingStatsTracker()
        let viewModel = makeViewModel(chartType: .columns, tracker: tracker)

        viewModel.selectChartType(.line)

        #expect(viewModel.selectedChartType == .line)
        #expect(viewModel.configuration.chartType == .line)

        let event = try #require(tracker.events.first)
        guard case .chartTypeChanged = event.name else {
            Issue.record("Expected chartTypeChanged event")
            return
        }
        #expect(
            event.properties == [
                "from_type": "columns",
                "to_type": "line"
            ]
        )
        #expect(tracker.events.count == 1)
    }

    @Test("Selecting the current chart type does not track a change")
    func selectCurrentChartType() {
        let tracker = RecordingStatsTracker()
        let viewModel = makeViewModel(chartType: .columns, tracker: tracker)

        viewModel.selectChartType(.columns)

        #expect(viewModel.selectedChartType == .columns)
        #expect(tracker.events.isEmpty)
    }

    private func makeViewModel(chartType: ChartType, tracker: RecordingStatsTracker) -> ChartCardViewModel {
        let calendar = Calendar.mock()
        return ChartCardViewModel(
            configuration: ChartCardConfiguration(metrics: [.views], chartType: chartType),
            dateRange: calendar.makeDateRange(for: .last7Days),
            service: MockStatsService(timeZone: calendar.timeZone),
            tracker: tracker
        )
    }
}

private final class RecordingStatsTracker: StatsTracker, @unchecked Sendable {
    struct Event {
        let name: StatsEvent
        let properties: [String: String]
    }

    private let lock = NSLock()
    private var recordedEvents: [Event] = []

    var events: [Event] {
        lock.lock()
        defer { lock.unlock() }
        return recordedEvents
    }

    func send(_ event: StatsEvent, properties: [String: String]) {
        lock.lock()
        defer { lock.unlock() }
        recordedEvents.append(Event(name: event, properties: properties))
    }
}
