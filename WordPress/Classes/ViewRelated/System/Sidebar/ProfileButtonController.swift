import UIKit
import Combine
import WordPressData
import Gravatar
import AsyncImageKit

/// Controller for managing profile button avatar display in navigation bars
final class ProfileButtonController {
    private weak var barButtonItem: UIBarButtonItem?
    private var cancellables: [AnyCancellable] = []

    init(barButtonItem: UIBarButtonItem) {
        self.barButtonItem = barButtonItem
        setupNotificationObservers()
        configureButtonImage()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Private Methods

    private func defaultAccount() -> WPAccount? {
        try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
    }

    private func configureButtonImage() {
        barButtonItem?.image = UIImage(systemName: "person.crop.circle")
        downloadAvatar()
    }

    private func downloadAvatar(forceRefresh: Bool = false) {
        guard let account = defaultAccount(),
              let email = account.email else {
            return
        }

        ImageDownloader.shared.downloadGravatarImage(with: email, forceRefresh: forceRefresh) { [weak self] image in
            guard let image else {
                return
            }

            self?.configureGravatarImage(image)
        }
    }

    private func configureGravatarImage(_ image: UIImage) {
        let gravatarIcon = image.gravatarIcon(size: 32.0)
        barButtonItem?.image = gravatarIcon
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAvatar(_:)), name: .GravatarQEAvatarUpdateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateGravatarImage(_:)), name: .GravatarImageUpdateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(accountDidChange), name: .wpAccountDefaultWordPressComAccountChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(accountDidChange), name: .WPAccountEmailAndDefaultBlogUpdated, object: nil)
    }

    @objc private func refreshAvatar(_ notification: Foundation.Notification) {
        guard let email = defaultAccount()?.email,
              notification.userInfoHasEmail(email) else { return }
        downloadAvatar(forceRefresh: true)
    }

    @objc private func updateGravatarImage(_ notification: Foundation.Notification) {
        guard let userInfo = notification.userInfo,
              let email = userInfo["email"] as? String,
              let image = userInfo["image"] as? UIImage,
              let url = AvatarURL.url(for: email) else {
            return
        }
        configureGravatarImage(image)
    }

    @objc private func accountDidChange() {
        configureButtonImage()
    }
}
