extension MySiteViewController {

    static let jetpackBannerInsets = UIEdgeInsets(top: 0, left: 0, bottom: 44, right: 0)

    func startObservingJetpackBanner() {
        NotificationCenter.default.addObserver(forName: .jetpackBannerToggled,
                                               object: nil,
                                               queue: nil) { [weak self] notification in
            guard let isVisible = notification.object as? Bool else {
                return
            }

            self?.additionalSafeAreaInsets = isVisible ? Self.jetpackBannerInsets : .zero
        }

    }
}
