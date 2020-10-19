import UIKit

class ImageDimensionParser {
    private(set) var format: ImageDimensionFormat?
    private(set) var imageSize: CGSize? = nil

    private var data: Data

    init(with data: Data = Data()) {
        self.data = data

        parse()
    }

    public func append(bytes: Data) {
        data.append(contentsOf: bytes)

        parse()
    }

    private func parse() {
        guard
            let format = ImageDimensionFormat(with: data)
        else {
            return
        }

        self.format = format
        imageSize = dimensions(with: data)

        guard imageSize != nil else {
            return
        }
    }

    // MARK: - Dimension Calculating
    private func dimensions(with data: Data) -> CGSize? {
        switch format {
            case .png: return pngSize(with: data)
            case .gif: return gifSize(with: data)
            case .jpeg: return jpegSize(with: data)

            default: return nil
        }
    }

    // MARK: - PNG Parsing
    private func pngSize(with data: Data) -> CGSize? {
        // Bail out if the data size is too small to read the header
        let chunkSize = PNGConstants.chunkSize
        let ihdrStart = PNGConstants.headerSize + chunkSize

        // The min length needed to read the width / height
        let minLength = ihdrStart + chunkSize * 3

        guard data.count >= minLength else {
            return nil
        }

        // Validate the header to make sure the width/height is in the correct spot
        guard data.subdata(start: ihdrStart, length: chunkSize) == PNGConstants.IHDR else {
            return nil
        }

        // Width is immediately after the IHDR header
        let widthOffset = ihdrStart + chunkSize

        // Height is after the width
        let heightOffset = widthOffset + chunkSize

        // Height and width are stored as 32 bit ints
        // http://www.libpng.org/pub/png/spec/1.0/PNG-Chunks.html
        // ^ The maximum for each is (2^31)-1 in order to accommodate languages that have difficulty with unsigned 4-byte values.
        let width = CFSwapInt32(data[widthOffset, chunkSize] as UInt32)
        let height = CFSwapInt32(data[heightOffset, chunkSize] as UInt32)

        return CGSize(width: Int(width), height: Int(height))
    }

    private struct PNGConstants {
        // PNG header size is 8 bytes
        static let headerSize = 8

        // PNG is broken up into 4 byte chunks, except for the header
        static let chunkSize = 4

        // IHDR header: // https://www.w3.org/TR/PNG/#11IHDR
        static let IHDR = Data([0x49, 0x48, 0x44, 0x52])
    }

    // MARK: - GIF Parsing
    private func gifSize(with data: Data) -> CGSize? {
        // Bail out if the data size is too small to read the header
        let valueSize = GIFConstants.valueSize
        let headerSize = GIFConstants.headerSize

        // Min length we need to read is the header size + 4 bytes
        let minLength = headerSize + valueSize * 3

        guard data.count >= minLength else {
            return nil
        }

        // The width appears directly after the header, and the height after that.
        let widthOffset = headerSize
        let heightOffset = widthOffset

        // Reads the "logical screen descriptor" which appears after the GIF header block
        let width: UInt16 = data[widthOffset, valueSize]
        let height: UInt16 = data[heightOffset, valueSize]

        return CGSize(width: Int(width), height: Int(height))
    }

    private struct GIFConstants {
        // http://www.matthewflickinger.com/lab/whatsinagif/bits_and_bytes.asp

        // The GIF header size is 6 bytes
        static let headerSize = 6

        // The height and width are stored as 2 byte values
        static let valueSize = 2
    }

    // MARK: - JPEG Parsing
    private struct JPEGConstants {
        static let blockSize: UInt16 = 256

        // 16 bytes skips the header and the first block
        static let minDataCount = 16

        static let valueSize = 2
        static let heightOffset = 5

        // JFIF{NULL}
        static let jfifHeader = Data([0x4A, 0x46, 0x49, 0x46, 0x00])
    }

    private func jpegSize(with data: Data) -> CGSize? {
        // Bail out if the data size is too small to read the header
        guard data.count > JPEGConstants.minDataCount else {
            return nil
        }

        // Adapted from:
        // - https://web.archive.org/web/20131016210645/http://www.64lines.com/jpeg-width-height

        var i = JPEGConstants.jfifHeader.count - 1

        let blockSize: UInt16 = JPEGConstants.blockSize

        // Retrieve the block length of the first block since the first block will not contain the size of file
        var block_length = UInt16(data[i]) * blockSize + UInt16(data[i+1])

        while i < data.count {
            i += Int(block_length)

            // Protect again out of bounds issues
            // 10 = the max size we need to read all the values from below
            if i + 10 >= data.count {
                return nil
            }

            // Check that we are truly at the start of another block
            if data[i] != 0xFF {
                return nil
            }

            // SOFn marker
            let marker = data[i+1]

            let isValidMarker = (marker >= 0xC0 && marker <= 0xC3) ||
                                (marker >= 0xC5 && marker <= 0xC7) ||
                                (marker >= 0xC9 && marker <= 0xCB) ||
                                (marker >= 0xCD && marker <= 0xCF)

            if isValidMarker {
                // "Start of frame" marker which contains the file size
                let valueSize = JPEGConstants.valueSize
                let heightOffset = i + JPEGConstants.heightOffset
                let widthOffset = heightOffset + valueSize

                let height = CFSwapInt16(data[heightOffset, valueSize] as UInt16)
                let width = CFSwapInt16(data[widthOffset, valueSize] as UInt16)

                return CGSize(width: Int(width), height: Int(height))
            }

            // Go to the next block
            i += 2 // Skip the block marker
            block_length = UInt16(data[i]) * blockSize + UInt16(data[i+1])
        }

        return nil
    }
}

// MARK: - ImageFormat
enum ImageDimensionFormat {
    // WordPress supported image formats:
    // https://wordpress.com/support/images/
    // https://codex.wordpress.org/Uploading_Files
    case jpeg
    case png
    case gif
    case unsupported

    init?(with data: Data) {
        if data.headerIsEqual(to: FileMarker.jpeg) {
            self = .jpeg
        }
        else if data.headerIsEqual(to: FileMarker.gif) {
            self = .gif
        }
        else if data.headerIsEqual(to: FileMarker.png) {
            self = .png
        }
        else if data.count < FileMarker.png.count {
            return nil
        }
        else {
            self = .unsupported
        }
    }

    // File type markers denote the type of image in the first few bytes of the file
    private struct FileMarker {
        // https://en.wikipedia.org/wiki/JPEG_Network_Graphics
        static let png = Data([0x89, 0x50, 0x4E, 0x47])

        // https://en.wikipedia.org/wiki/JPEG_File_Interchange_Format
        // FFD8 = SOI, APP0 marker
        static let jpeg = Data([0xFF, 0xD8, 0xFF])

        // https://en.wikipedia.org/wiki/GIF
        static let gif = Data([0x47, 0x49, 0x46, 0x38]) //GIF8
    }
}



// MARK: - Private: Extensions
private extension Data {
    func headerData(with length: Int) -> Data {
        return subdata(start: 0, length: length)
    }

    func headerIsEqual(to value: Data) -> Bool {
        // Prevent any out of bounds issues
        if count < value.count {
            return false
        }

        let header = headerData(with: value.count)

        return header == value
    }

    func subdata(start: Int, length: Int) -> Data {
        return subdata(in: start ..< start + length)
    }

    subscript<UInt16>(range: Range<Data.Index>) -> UInt16 {
       return subdata(in: range).withUnsafeBytes { $0.load(as: UInt16.self) }
    }

    subscript<T>(start: Int, length: Int) -> T {
        return self[start..<start + length]
    }
}
