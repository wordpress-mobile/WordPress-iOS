// MARK: - UIImage + Crop Method
//
extension UIImage {

    /// This method crops an image to the specified rect
    ///
    public func cropping(to rect: CGRect) -> UIImage {
        // Correct rect size based on the device screen scale
        let scaledRect = CGRect(x: rect.origin.x * self.scale,
                                y: rect.origin.y * self.scale,
                                width: rect.size.width * self.scale,
                                height: rect.size.height * self.scale)

        if let croppedImage = self.cgImage?.cropping(to: scaledRect) {
            return UIImage(cgImage: croppedImage, scale: self.scale, orientation: self.imageOrientation)
        }
        return self
    }
}

