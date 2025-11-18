import Foundation
import WordPressShared

extension ReaderPost {

    @objc public override var featuredImageURL: URL? {
        if !self.featuredImage.isEmpty {
            return URL(string: self.featuredImage)
        }
        return nil
    }
}

