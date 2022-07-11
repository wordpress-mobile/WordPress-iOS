import Foundation

extension SuggestionType {
    var trigger: String {
        switch self {
        case .mention: return "@"
        case .xpost: return "+"
        }
    }
}

@objc extension SuggestionsTableView {

    // MARK: - API

    @objc convenience init(viewModel: SuggestionsListViewModelType, delegate: SuggestionsTableViewDelegate) {
        self.init(anyViewModel: viewModel, delegate: delegate)
    }

    /// Returns the a list of prominent suggestions excluding the current user.
    static func prominentSuggestions(fromPostAuthorId postAuthorId: NSNumber?, commentAuthorId: NSNumber?, defaultAccountId: NSNumber?) -> [NSNumber] {
        return [postAuthorId, commentAuthorId].compactMap { $0 != defaultAccountId ? $0 : nil }
    }

    // MARK: - Internal

    func loadImage(for suggestion: SuggestionViewModel, in cell: SuggestionsTableViewCell, at indexPath: IndexPath, with viewModel: SuggestionsListViewModelType) {
        cell.iconImageView.image = UIImage(named: "gravatar")
        guard let imageURL = suggestion.imageURL else { return }
        cell.imageDownloadHash = imageURL.hashValue

        retrieveIcon(for: imageURL) { image in
            guard indexPath.row < viewModel.items.count else { return }
            if let reloadedImageURL = viewModel.items[indexPath.row].imageURL, reloadedImageURL.hashValue == cell.imageDownloadHash {
                cell.iconImageView.image = image
            }
        }
    }

    // MARK: - Private

    private func retrieveIcon(for imageURL: URL?, success: @escaping (UIImage?) -> Void) {
        let imageSize = CGSize(width: SuggestionsTableViewCellIconSize, height: SuggestionsTableViewCellIconSize)

        if let image = cachedIcon(for: imageURL, with: imageSize) {
            success(image)
        } else {
            fetchIcon(for: imageURL, with: imageSize, success: success)
        }
    }

    private func cachedIcon(for imageURL: URL?, with size: CGSize) -> UIImage? {
        var hash: NSString?
        let type = avatarSourceType(for: imageURL, with: &hash)

        if let hash = hash, let type = type {
            return WPAvatarSource.shared()?.cachedImage(forAvatarHash: hash as String, of: type, with: size)
        }
        return nil
    }

    private func fetchIcon(for imageURL: URL?, with size: CGSize, success: @escaping ((UIImage?) -> Void)) {
        var hash: NSString?
        let type = avatarSourceType(for: imageURL, with: &hash)

        if let hash = hash, let type = type {
            WPAvatarSource.shared()?.fetchImage(forAvatarHash: hash as String, of: type, with: size, success: success)
        } else {
            success(nil)
        }
    }
}

extension SuggestionsTableView {
    func avatarSourceType(for imageURL: URL?, with hash: inout NSString?) -> WPAvatarSourceType? {
        if let imageURL = imageURL {
            return WPAvatarSource.shared()?.parseURL(imageURL, forAvatarHash: &hash)
        }
        return .unknown
    }
}
