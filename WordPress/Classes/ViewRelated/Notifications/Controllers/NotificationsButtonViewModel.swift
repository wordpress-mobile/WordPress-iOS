import Foundation
import Combine
import UIKit
import SwiftUI

final class NotificationsButtonViewModel: ObservableObject {
    @Published private(set) var counter = 0
    @Published private(set) var image: UIImage?

    private var cancellables: [AnyCancellable] = []

    init() {
        refresh()

        NotificationCenter.default
            .publisher(for: NSNotification.ZendeskPushNotificationReceivedNotification)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: NSNotification.ZendeskPushNotificationClearedNotification)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)

        UIApplication.shared
            .publisher(for: \.applicationIconBadgeNumber)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)
    }

    private func refresh() {
        counter = UIApplication.shared.applicationIconBadgeNumber - ZendeskUtils.unreadNotificationsCount

        if counter > 0 {
            image = UIImage(systemName: "bell.badge")?
                .withConfiguration(UIImage.SymbolConfiguration(paletteColors: [.systemRed, .label]))
        } else {
            image = UIImage(systemName: "bell")
        }
    }
}
