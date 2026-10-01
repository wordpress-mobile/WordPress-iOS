import Foundation
import AsyncImageKit

/// The dependencies of the unified support flow.
///
/// It's separate from `SupportDataProvider`, so the unified flow doesn't change the existing support screens.
@MainActor
public final class UnifiedSupportContext: ObservableObject {
    let dataProvider: any UnifiedSupportDataProvider
    let tracker: any UnifiedSupportTracker

    /// Authenticates the requests for private attachments.
    let mediaHost: any MediaHostProtocol

    /// Backs the application log picker the reply form shares with the other support screens.
    let supportDataProvider: SupportDataProvider

    public init(
        dataProvider: any UnifiedSupportDataProvider,
        tracker: any UnifiedSupportTracker,
        mediaHost: any MediaHostProtocol,
        supportDataProvider: SupportDataProvider
    ) {
        self.dataProvider = dataProvider
        self.tracker = tracker
        self.mediaHost = mediaHost
        self.supportDataProvider = supportDataProvider
    }
}
