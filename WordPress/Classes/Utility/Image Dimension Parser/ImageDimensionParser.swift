import UIKit

class ImageDimensionParser {
    private(set) var format: ImageDimensionFormat?
    private(set) var imageSize: CGSize? = nil

    private var data: Data = Data()

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

        print("Finished parsing:", data.count / 1024, "kb")
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
        guard data.count >= 25 else {
            return nil
        }

        // https://www.w3.org/TR/PNG/#11IHDR
        let validHeader = "IHDR".data(using: .ascii)

        // Validate the header to make sure the width/height is in the correct spot
        // This can happen if the image has been
        guard data.subdata(in: NSRange(location: 12, length: 4)) == validHeader else {
            return nil
        }

        // Height and width are stored as 32 bit ints
        // http://www.libpng.org/pub/png/spec/1.0/PNG-Chunks.html
        // ^ The maximum for each is (2^31)-1 in order to accommodate languages that have difficulty with unsigned 4-byte values.
        let width = CFSwapInt32(data[16, 4] as UInt32)
        let height = CFSwapInt32(data[20, 4] as UInt32)

        return CGSize(width: Int(width), height: Int(height))
    }

    // MARK: - GIF Parsing
    private func gifSize(with data: Data) -> CGSize? {
        // Bail out if the data size is too small to read the header
        guard data.count >= 11 else {
            return nil
        }

        // http://www.matthewflickinger.com/lab/whatsinagif/bits_and_bytes.asp
        // Reads the "logical screen descriptor" which appears after the Gif header block
        let width: UInt16 = data[6, 2]
        let height: UInt16 = data[8, 2]

        return CGSize(width: Int(width), height: Int(height))
    }

    // MARK: - JPEG Parsing
    private func jpegSize(with data: Data) -> CGSize? {
        // Bail out if the data size is too small to read the header
        guard data.count >= 12 else {
            return nil
        }
        // https://web.archive.org/web/20131016210645/http://www.64lines.com/jpeg-width-height
        var i: Int = 0
        // Check for valid JPEG image
        guard data[i] == 0xFF && data[i+1] == 0xD8 && data[i+2] == 0xFF && data[i+3] == 0xE0 else {
            return nil
        }

        i += 4

        // Check for valid JPEG header (null terminated JFIF)
        let jfifHeader = "JFIF\0".data(using: .ascii)
        guard data.subdata(in: NSRange(location: i+2, length: 5)) == jfifHeader else {
            return nil
        }

        let blockSize: UInt16 = 256
        // Retrieve the block length of the first block since the first block will not contain the size of file
        var block_length = UInt16(data[i]) * blockSize + UInt16(data[i+1])

        while i < data.count {

            i += Int(block_length)

            // Check to protect against segmentation faults
            if i + 10 >= data.count {
                return nil
            }

            //Check that we are truly at the start of another block
            if data[i] != 0xFF {
                return nil
            }

            // SOF0, SOF1, SOF2 markers
            // https://help.accusoft.com/ImageGear/v18.2/Windows/ActiveX/IGAX-10-12.html
            if data[i+1] >= 0xC0 && data[i+1] <= 0xC3 {
                // "Start of frame" marker which contains the file size
                let height = CFSwapInt16(data[i + 5, 2] as UInt16)
                let width = CFSwapInt16(data[i + 7, 2] as UInt16)

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
        static let jpeg = Data([0xFF, 0xD8, 0xFF])

        // https://en.wikipedia.org/wiki/GIF
        static let gif = Data([0x47, 0x49, 0x46, 0x38]) //GIF8
    }
}



// MARK: - Private: Extensions
private extension Data {
    func headerData(with length: Int) -> Data {
        return subdata(in: NSRange(location: 0, length: length))
    }

    func headerIsEqual(to value: Data) -> Bool {
        // Prevent any out of bounds issues
        if count < value.count {
            return false
        }

        let header = headerData(with: value.count)

        return header == value
    }

    func subdata(in range: NSRange) -> Data {
        return subdata(in: range.location ..< range.location + range.length)
    }

    subscript<UInt16>(range: Range<Data.Index>) -> UInt16 {
       return subdata(in: range).withUnsafeBytes { $0.load(as: UInt16.self) }
    }

    subscript<T>(start: Int, length: Int) -> T {
        return self[start..<start + length]
    }
}
