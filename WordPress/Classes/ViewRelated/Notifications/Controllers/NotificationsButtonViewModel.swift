import Foundation
import Combine
import UIKit
import SwiftUI

final class NotificationsButtonViewModel: ObservableObject {
    @Published private(set) var counter = 0
    @Published private(set) var image: UIImage?

    private var cancellables: [AnyCancellable] = []
    private let badgeObserver = NotificationBadgeObserver()

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

        badgeObserver.onChange = { [weak self] in self?.refresh() }
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

final class NotificationBadgeObserver: NSObject {
    var onChange: () -> Void = {}

    private let keyPath = "applicationIconBadgeNumber"

    deinit {
        UIApplication.shared.removeObserver(self, forKeyPath: keyPath)
    }

    /// - warning: The `applicationIconBadgeNumber` API is getting deprecated,
    /// and it has some issues that seemingly prevent it being used from Combine.
    override init() {
        super.init()

        UIApplication.shared.addObserver(self, forKeyPath: keyPath, options: [.new], context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        onChange()
    }
}
