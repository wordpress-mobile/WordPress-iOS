import UIKit
import SwiftUI
import DesignSystem
import Gravatar

public extension ContentPreview.ImageConfiguration {

    init(avatar: Avatar) {
        self.init(url: Self.avatarURL(from: avatar), placeholder: Image("gravatar"))
    }

    private static func avatarURL(from avatar: Avatar) -> URL? {
        if let url = avatar.url {
            return url
        } else if let email = avatar.email {
            let pixels = Int(ceil(avatar.size * UIScreen.main.scale))
            return AvatarURL.url(for: email, preferredSize: .pixels(pixels), gravatarRating: .general)
        }
        return nil
    }

    struct Avatar {
        let url: URL?
        let email: String?
        let size: CGFloat

        init(url: URL?, email: String?, size: CGFloat = 80) {
            self.url = url
            self.email = email
            self.size = size
        }
    }
}
