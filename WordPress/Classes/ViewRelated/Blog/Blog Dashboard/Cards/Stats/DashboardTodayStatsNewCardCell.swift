import UIKit
import SwiftUI
import JetpackStats
import WordPressData
import WordPressShared
import WordPressKit
import Logging

/// Dashboard cell that renders the new Stats "Today" card (the same UI, sparkline
/// included, as the new Stats screen) when `FeatureFlag.newStats` is enabled.
///
/// It is frameless: `StatsTodayCardView` brings its own card chrome, header, and
/// date, so wrapping it in `BlogDashboardCardFrameView` would double the title.
/// The card fetches its own hourly data through the module (independent of the
/// dashboard's batched `todays_stats` payload, which lacks hourly series and
/// still gates visibility).
final class DashboardTodayStatsNewCardCell: DashboardCollectionViewCell {

    private weak var presentingViewController: BlogDashboardViewController?

    private var controller: StatsTodayCardController?
    private var hostingController: UIHostingController<AnyView>?

    /// The dotCom ID the current `controller` was built for, so a site switch (cell
    /// reuse across sites, or an in-place switch on My Site) can be detected and
    /// the controller rebuilt instead of showing the previous site's data.
    private var controllerSiteID: Int?

    private static let logger = Logger(label: "org.wordpress.dashboard.stats-today")

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        observeAppForeground()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        observeAppForeground()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        teardownController()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        refreshIfVisible()
    }

    private func observeAppForeground() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshIfVisible),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    /// Retries a failed load, refreshes TTL-expired data, and rolls the range
    /// over after midnight. Covers the cases where `configure` is not called
    /// again: scrolling the cell back into view / a tab switch (`didMoveToWindow`)
    /// and returning from the background (`willEnterForeground`), where the
    /// dashboard reapplies an unchanged snapshot without re-configuring the cell.
    /// `refreshIfNeeded()` is a no-op when the data is fresh, so this is cheap.
    @objc private func refreshIfVisible() {
        if window != nil {
            controller?.refreshIfNeeded()
        }
    }

    // MARK: - BlogDashboardCardConfigurable

    func configure(blog: Blog, viewController: BlogDashboardViewController?, apiResponse: BlogDashboardRemoteEntity?) {
        guard let viewController else {
            return
        }

        self.presentingViewController = viewController

        let siteID = blog.dotComID?.intValue
        if let controller, let siteID, controllerSiteID == siteID {
            // Same site: keep the controller (preserving the service cache) and refresh.
            controller.refreshIfNeeded()
        } else {
            // First configuration, or a site switch: cancel any in-flight load
            // and rebuild the context, controller, and hosted view.
            rebuildController(for: blog, in: viewController)
        }

        guard controller != nil else {
            return
        }

        // Fire the same card-shown analytics as the legacy card (reporting the
        // `todays_stats` identity). The dashboard's `StatsContext` has no tracker,
        // so the module emits nothing; these dashboard events are the only ones.
        BlogDashboardAnalytics.shared.track(
            .dashboardCardShown,
            properties: ["type": DashboardCard.todaysStats.rawValue],
            blog: blog
        )
    }

    // MARK: - Controller lifecycle

    private func rebuildController(for blog: Blog, in viewController: BlogDashboardViewController) {
        teardownController()

        guard let context = StatsContext.dashboard(blog: blog) else {
            // Eligibility passed (`DashboardCard.newStatsActive`) but the context
            // could not be built (e.g. a logout raced this parse). Render nothing
            // and log; the next dashboard parse selects the legacy card.
            Self.logger.error("Failed to build StatsContext for the dashboard Today card (site: \(blog.dotComID?.intValue ?? -1))")
            return
        }

        let controller = StatsTodayCardController(context: context)
        controller.onLoadError = { error in
            // The dashboard context installs no tracker, so log the degraded
            // state here to keep it diagnosable without touching analytics.
            Self.logger.error("Stats Today card load failed: \(String(describing: error))")
        }
        self.controller = controller
        self.controllerSiteID = blog.dotComID?.intValue

        // Wrap the whole card in a plain Button (mirroring the Stats screen's
        // TrafficTabView) so the tap carries button/accessibility semantics
        // instead of a bare tap gesture. The card's own ellipsis Menu keeps
        // working nested inside, exactly as on the Stats screen.
        let rootView = Button(action: { [weak self] in
            self?.showStats(for: blog)
        }) {
            StatsTodayCardView(controller: controller) { [weak self] in
                if let self {
                    self.makeMenu(for: blog)
                }
            }
        }
        .buttonStyle(.plain)

        let hostingController = UIHostingController(rootView: AnyView(rootView))
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.willMove(toParent: viewController)
        viewController.addChild(hostingController)
        contentView.addSubview(hostingController.view)
        contentView.pinSubviewToAllEdges(hostingController.view, priority: UILayoutPriority(999))
        hostingController.didMove(toParent: viewController)
        hostingController.view.invalidateIntrinsicContentSize()
        self.hostingController = hostingController
    }

    private func teardownController() {
        controller?.cancel()
        controller = nil
        controllerSiteID = nil
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        hostingController = nil
    }

    // MARK: - Dashboard menu

    @ViewBuilder
    private func makeMenu(for blog: Blog) -> some View {
        Button(action: { [weak self] in
            self?.showStats(for: blog)
        }) {
            Label(Strings.viewStats, systemImage: "chart.bar.xaxis")
        }
        // Menu items only appear on screen when the menu is actually presented,
        // so `onAppear` here fires once per open, matching the legacy frame
        // view's `onEllipsisButtonTap` tracking. Logging in this builder's body
        // instead would over-count: SwiftUI evaluates it on every host
        // re-render. `.todaysStatsNew` reports the legacy `todays_stats` card
        // identity, keeping the event continuous across the flag.
        .onAppear {
            BlogDashboardAnalytics.trackContextualMenuAccessed(for: DashboardCard.todaysStatsNew)
        }
        Button(role: .destructive, action: { [weak self] in
            self?.hideCard(for: blog)
        }) {
            Label(Strings.hideThis, systemImage: "minus.circle")
        }
    }

    // MARK: - Actions

    private func showStats(for blog: Blog) {
        WPAnalytics.track(
            .dashboardCardItemTapped,
            properties: ["type": DashboardCard.todaysStats.rawValue],
            blog: blog
        )
        RootViewCoordinator.sharedPresenter.showStats(for: blog, source: .todayStatsCard, tab: .traffic, unit: .day, date: nil)
    }

    private func hideCard(for blog: Blog) {
        // Mirrors `BlogDashboardHelpers.makeHideCardAction`. Writing the shared
        // personalization key hides both the legacy and the new rendering.
        BlogDashboardAnalytics.trackHideTapped(for: DashboardCard.todaysStatsNew)
        BlogDashboardPersonalizationService(siteID: blog.dotComID?.intValue ?? 0)
            .setEnabled(false, for: DashboardCard.todaysStatsNew)
    }
}

// MARK: - Constants

private extension DashboardTodayStatsNewCardCell {

    enum Strings {
        static let viewStats = NSLocalizedString("dashboardCard.stats.viewStats", value: "View stats", comment: "Title for the View stats button in the More menu")
        static let hideThis = NSLocalizedString("blogDashboard.contextMenu.hideThis", value: "Hide this", comment: "Title for the context menu action that hides the dashboard card.")
    }
}
