import Foundation

enum ImageDecoder {
    static func makeImage(from fileURL: URL) async throws -> UIImage {
        let data = try Data(contentsOf: fileURL)
        return try _makeImage(from: data)
    }

    static func makeImage(from data: Data) async throws -> UIImage {
        try _makeImage(from: data)
    }
}

// Forces decompression (or bitmapping) to happen in the background.
// It's very expensive for some image formats, such as JPEG.
private func _makeImage(from data: Data) throws -> UIImage {
    guard let image = UIImage(data: data) else {
        throw URLError(.cannotDecodeContentData)
    }
    if data.isMatchingMagicNumbers(Data.gifMagicNumbers) {
        return AnimatedImageWrapper(gifData: data) ?? image
    }
    guard isDecompressionNeeded(for: data) else {
        return image
    }
    return image.preparingForDisplay() ?? image
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
