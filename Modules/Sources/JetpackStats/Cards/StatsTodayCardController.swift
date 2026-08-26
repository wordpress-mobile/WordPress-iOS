import SwiftUI

/// Public, controller-driven entry point for embedding the Stats "Today" card
/// outside the Stats screen (currently the My Site dashboard).
///
/// The internal `TodayCard`/`TodayCardViewModel` load only on first appearance
/// and expose no reload path, so an embedder that keeps a card on screen across
/// appearances needs an explicit lifecycle contract. This controller owns the
/// view model and forwards the reload/cancel decisions to it, keeping the
/// module's internals private.
@MainActor
public final class StatsTodayCardController: ObservableObject {
    let context: StatsContext
    let viewModel: TodayCardViewModel

    /// Called on the main actor when a load fails. The embedder uses this to log
    /// the degraded state, since the dashboard installs no analytics tracker on
    /// its `StatsContext` (so the module's own `trackError` is intentionally
    /// silent there).
    public var onLoadError: ((any Error) -> Void)? {
        didSet { viewModel.onLoadFailure = onLoadError }
    }

    public init(context: StatsContext) {
        self.context = context

        let configuration = TodayCardConfiguration(
            supportedMetrics: Set(context.service.supportedMetrics)
        )
        self.viewModel = TodayCardViewModel(
            configuration: configuration,
            dateRange: context.calendar.makeDateRange(for: .today),
            context: context
        )
    }

    /// Reloads the current period only when the loaded data can no longer be
    /// trusted (retry after failure, midnight rollover, or TTL staleness).
    /// Otherwise a no-op, preserving the service cache.
    public func refreshIfNeeded() {
        viewModel.refreshIfNeeded()
    }

    /// Cancels any in-flight load, so a stale response cannot land after the
    /// controller is torn down (for example on a site switch).
    public func cancel() {
        viewModel.cancelLoading()
    }
}

/// Renders the internal Stats "Today" card for an embedder, so the visual result
/// is identical to the Stats screen's card.
public struct StatsTodayCardView<MenuContent: View>: View {
    @ObservedObject private var controller: StatsTodayCardController
    private let menuContent: (() -> MenuContent)?

    /// Renders the card with caller-supplied more-menu items. The card still
    /// draws the ellipsis button itself, so only the items differ.
    public init(controller: StatsTodayCardController, @ViewBuilder menuContent: @escaping () -> MenuContent) {
        self.controller = controller
        self.menuContent = menuContent
    }

    public var body: some View {
        Group {
            if let menuContent {
                TodayCard(viewModel: controller.viewModel, menuContent: menuContent)
            } else {
                TodayCard(viewModel: controller.viewModel)
            }
        }
        .environment(\.context, controller.context)
    }
}

extension StatsTodayCardView where MenuContent == EmptyView {
    /// Uses the card's built-in more-menu (the Stats screen's behavior).
    public init(controller: StatsTodayCardController) {
        self.controller = controller
        self.menuContent = nil
    }
}
