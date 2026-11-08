import Combine
import UIKit

extension BlogDetailsViewController {

    /// Shows the account avatar in the Me row.
    func observeAccountAvatar() -> AnyCancellable {
        AccountAvatar.shared.$image.sink { [weak self] avatar in
            self?.tableViewModel?.gravatarIcon = avatar?.gravatarIcon(size: Metrics.iconSize)
        }
    }

    private enum Metrics {
        static let iconSize = 24.0
    }
}
