import Foundation

enum ImageDecoder {
    /// Returns an image created from the given URL. The image is decompressed.
    /// Returns ``AnimatedImage`` the image is a GIF.
    static func makeImage(from fileURL: URL) async throws -> UIImage {
        let data = try Data(contentsOf: fileURL)
        return try _makeImage(from: data, size: nil)
    }

    /// Returns an image created from the given data. The image is decompressed.
    /// Returns ``AnimatedImage`` the image is a GIF.
    ///
    /// - parameter size: The desired size of the thumbnail in pixels.
    static func makeImage(from data: Data, size: CGSize? = nil) async throws -> UIImage {
        try _makeImage(from: data, size: size)
    }
}

// Forces decompression (or bitmapping) to happen in the background.
// It's very expensive for some image formats, such as JPEG.
private func _makeImage(from data: Data, size: CGSize?) throws -> UIImage {
    guard let image = UIImage(data: data) else {
        throw URLError(.cannotDecodeContentData)
    }
    if data.isMatchingMagicNumbers(Data.gifMagicNumbers) {
        return AnimatedImage(gifData: data) ?? image
    }
    if let size {
        let size = aspectFillSize(imageSize: image.size.scaled(by: image.scale), targetSize: size)
        return image.preparingThumbnail(of: size) ?? image
    }
    if isDecompressionNeeded(for: data) {
        return image.preparingForDisplay() ?? image
    }
    return image
}

private func aspectFillSize(imageSize: CGSize, targetSize: CGSize) -> CGSize {
    // Scale image to fill the target size but avoid upscaling
    let scale = min(1, max(targetSize.width / imageSize.width, targetSize.height / imageSize.height))
    return imageSize.scaled(by: scale).rounded()
}

private func isDecompressionNeeded(for data: Data) -> Bool {
    // This check is required to avoid the following error messages when
    // using `preparingForDisplay`:
    //
    //    [Decompressor] Error -17102 decompressing image -- possibly corrupt
    //
    // More info: https://github.com/SDWebImage/SDWebImage/issues/3365
    data.isMatchingMagicNumbers(Data.jpegMagicNumbers)
}

private extension Data {
    // JPEG magic numbers https://en.wikipedia.org/wiki/JPEG
    static let jpegMagicNumbers: [UInt8] = [0xFF, 0xD8, 0xFF]

    // GIF magic numbers https://en.wikipedia.org/wiki/GIF
    static let gifMagicNumbers: [UInt8] = [0x47, 0x49, 0x46]

    func isMatchingMagicNumbers(_ numbers: [UInt8?]) -> Bool {
        guard self.count >= numbers.count else {
            return false
        }
        return zip(numbers.indices, numbers).allSatisfy { index, number in
            guard let number = number else { return true }
            return self[index] == number
        }
    }
}

private extension UIImage {
    var sizeInPixels: CGSize {
        size.scaled(by: scale)
    }
}
