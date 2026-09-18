import Foundation
import Support

extension UnifiedSupportContext {
    /// The unified support dependencies, backed by WordPress.com.
    @MainActor
    static let shared: UnifiedSupportContext = {
        let client = UnifiedSupportAPIClient()
        return UnifiedSupportContext(
            dataProvider: WpUnifiedSupportDataProvider(client: client),
            tracker: WpUnifiedSupportTracker(),
            mediaHost: client
        )
    }()
}
