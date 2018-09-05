// Empty states for Media Library

extension NoResultsViewController {

    @objc func configureForNoAssets(userCanUploadMedia: Bool) {
        let buttonTitle = userCanUploadMedia ? LocalizedText.uploadButtonTitle : nil
        configure(title: LocalizedText.noAssetsTitle, buttonTitle: buttonTitle, subtitle: nil, attributedSubtitle: nil, image: Constants.imageName)
    }

    @objc func configureForFetching() {
        configure(title: LocalizedText.fetchingTitle, buttonTitle: nil, subtitle: nil, attributedSubtitle: nil, image: nil, accessoryView: NoResultsViewController.loadingAccessoryView())
        view.layoutIfNeeded()
    }

    @objc func configureForNoSearchResult(with searchQuery: String) {
        configure(title: LocalizedText.noResultsTitle, buttonTitle: nil, subtitle: searchQuery, attributedSubtitle: nil, image: Constants.imageName)
    }

    private enum Constants {
        static let imageName = "media-no-results"
    }

    private struct LocalizedText {
        static let noAssetsTitle = NSLocalizedString("You don't have any media.", comment: "Title displayed when the user doesn't have any media in their media library. Should match Calypso.")
        static let uploadButtonTitle = NSLocalizedString("Upload Media", comment: "Title for button displayed when the user has an empty media library")
        static let fetchingTitle = NSLocalizedString("Fetching media...", comment: "Title displayed whilst fetching media from the user's media library")
        static let noResultsTitle = NSLocalizedString("No media files match your search for:", comment: "Message displayed when no results are returned from a media library search. Should match Calypso.")
    }

}
