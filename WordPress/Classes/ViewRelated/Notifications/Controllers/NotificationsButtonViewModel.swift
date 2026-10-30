import Foundation
import Combine
import UIKit
import SwiftUI

/// Drives the Notifications bell across SwiftUI and UIKit surfaces from the
/// account-scoped ``NotificationActivityService``. No longer reads the
/// deprecated `applicationIconBadgeNumber` or the Zendesk unread count.
@MainActor
final class NotificationsButtonViewModel: ObservableObject {
    @Published private(set) var hasNewActivity = false
    @Published private(set) var image: UIImage?

    private var cancellables: [AnyCancellable] = []

    /// - Parameter scope: The scope of the list the bell opens. The bell has no badge when that
    ///   list doesn't track the account's activity.
    init(scope: NotificationsListScope = .all, activityService: NotificationActivityService = .shared) {
        guard scope.tracksAccountActivity else {
            update(hasNewActivity: false)
            return
        }
        activityService.$hasNewActivity
            .sink { [weak self] in self?.update(hasNewActivity: $0) }
            .store(in: &cancellables)
    }

    private func update(hasNewActivity: Bool) {
        self.hasNewActivity = hasNewActivity

        if hasNewActivity {
            image = UIImage(systemName: "bell.badge")?
                .withConfiguration(UIImage.SymbolConfiguration(paletteColors: [.systemRed, .label]))
        } else {
            image = UIImage(systemName: "bell")
        }
    }
}

/// The bell icon for SwiftUI surfaces, with a badge when there is new activity.
struct NotificationsBellImage: View {
    let hasNewActivity: Bool

    var body: some View {
        if hasNewActivity {
            Image(systemName: "bell.badge")
                .foregroundStyle(.red, .primary)
        } else {
            Image(systemName: "bell")
        }
    }
}
