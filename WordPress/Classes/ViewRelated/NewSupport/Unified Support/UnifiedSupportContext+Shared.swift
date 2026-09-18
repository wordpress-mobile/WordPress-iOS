import Foundation
import Support

extension UnifiedSupportContext {
    /// The unified support dependencies, backed by WordPress.com.
    @MainActor
    static let shared: UnifiedSupportContext = {
        // The AI Assistant can take a while to answer.
        let client = WordPressDotComClient(requestTimeout: 120)
        return UnifiedSupportContext(
            dataProvider: WpUnifiedSupportDataProvider(client: client),
            tracker: WpUnifiedSupportTracker(),
            mediaHost: client
        )
    }()
}
