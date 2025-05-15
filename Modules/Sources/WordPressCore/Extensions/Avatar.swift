import Foundation
import WordPressAPI
import WordPressAPIInternal

extension Dictionary where Key == UserAvatarSize, Value == WpResponseString {

    public func avatarURL() -> URL? {
        guard let url = self[.size96] ?? self[.size48] ?? self[.size24], let url else {
            return nil
        }

        return URL(string: url)
    }

}
