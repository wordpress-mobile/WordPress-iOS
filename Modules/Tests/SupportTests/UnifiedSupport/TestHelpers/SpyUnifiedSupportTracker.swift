import Foundation
import os
@testable import Support

final class SpyUnifiedSupportTracker: UnifiedSupportTracker {

    private let events = OSAllocatedUnfairLock<[UnifiedSupportEvent]>(initialState: [])

    var trackedEvents: [UnifiedSupportEvent] {
        events.withLock { $0 }
    }

    func track(_ event: UnifiedSupportEvent) {
        events.withLock { $0.append(event) }
    }
}
