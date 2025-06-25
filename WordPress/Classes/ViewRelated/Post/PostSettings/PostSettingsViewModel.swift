import Foundation
import WordPressData

final class PostSettingsViewModel: ObservableObject {
    let post: AbstractPost

    var onSaveTapped: (() -> Void)?

    init(post: AbstractPost) {
        self.post = post
    }
}
