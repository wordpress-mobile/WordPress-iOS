import Foundation

extension UITabBarItem {

    func downloadGravatarImage(with email: String, placeholderImage: UIImage) {
        self.image = placeholderImage

        guard let url = gravatarUrl(for: email) else {
            return
        }

        ImageDownloader.shared.downloadImage(at: url) { image, _ in
            DispatchQueue.main.async {

                guard let image else {
                    return
                }

                self.resizeAndUpdateGravatarImage(image)
            }
        }
    }

    func resizeAndUpdateGravatarImage(_ image: UIImage) {
        let iconDimension = 24.0
        let iconSize = CGSize(width: iconDimension, height: iconDimension)
        let resizedImage = image.resizedImage(iconSize, interpolationQuality: .default)
        self.image = resizedImage?.cropToCircle().withRenderingMode(.alwaysOriginal)
    }
}

extension UITabBarItem {

    private func gravatarUrl(for email: String) -> URL? {
        let baseURL = "https://gravatar.com/avatar"
        let hash = gravatarHash(of: email)
        let size = 80
        let targetURL = String(format: "%@/%@?d=404&s=%d&r=g", baseURL, hash, size)
        return URL(string: targetURL)
    }

    private func gravatarHash(of email: String) -> String {
        return email
            .lowercased()
            .trimmingCharacters(in: .whitespaces)
            .md5Hash()
    }
}

extension UIImage {

    func cropToCircle() -> UIImage {
        let imageWidth = size.width
        let imageHeight = size.height

        let diameter = min(imageWidth, imageHeight)
        let isLandscape = imageWidth > imageHeight

        let xOffset = isLandscape ? (imageWidth - diameter) / 2 : 0
        let yOffset = isLandscape ? 0 : (imageHeight - diameter) / 2

        let imageSize = CGSize(width: diameter, height: diameter)

        return UIGraphicsImageRenderer(size: imageSize).image { _ in
            let ovalPath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: imageSize))
            ovalPath.addClip()
            draw(at: CGPoint(x: -xOffset, y: -yOffset))
        }
    }
}
