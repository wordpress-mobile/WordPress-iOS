import Foundation

enum MultipartFormError: Swift.Error {
    case inaccessbileFile(path: String)
    case impossible
}

struct MultipartFormField {
    let name: String
    let filename: String?
    let mimeType: String?
    let bytes: UInt64

    fileprivate let inputStream: InputStream

    init(text: String, name: String, filename: String? = nil, mimeType: String? = nil) {
        self.init(data: text.data(using: .utf8)!, name: name, filename: filename, mimeType: mimeType)
    }

    init(data: Data, name: String, filename: String? = nil, mimeType: String? = nil) {
        self.inputStream = InputStream(data: data)
        self.name = name
        self.filename = filename
        self.bytes = UInt64(data.count)
        self.mimeType = mimeType
    }

    init(fileAtPath path: String, name: String, filename: String? = nil, mimeType: String? = nil) throws {
        guard let inputStream = InputStream(fileAtPath: path),
              let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let bytes = (attrs[FileAttributeKey.size] as? NSNumber)?.uint64Value else {
            throw MultipartFormError.inaccessbileFile(path: path)
        }
        self.inputStream = inputStream
        self.name = name
        self.filename = filename ?? path.split(separator: "/").last.flatMap({ String($0) })
        self.bytes = bytes
        self.mimeType = mimeType
    }
}

extension Array where Element == MultipartFormField {
    private func multipartFormDestination(forceWriteToFile: Bool) throws -> (outputStream: OutputStream, tempFilePath: String?) {
        let dest: OutputStream
        let tempFilePath: String?

        // Build the form data in memory if the content is estimated to be less than 10 MB. Otherwise, use a temporary file.
        let thresholdBytesForUsingTmpFile = 10_000_000
        let estimatedFormDataBytes = reduce(0) { $0 + $1.bytes }
        if forceWriteToFile || estimatedFormDataBytes > thresholdBytesForUsingTmpFile {
            let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
            guard let stream = OutputStream(toFileAtPath: tempFile, append: false) else {
                throw MultipartFormError.inaccessbileFile(path: tempFile)
            }
            dest = stream
            tempFilePath = tempFile
        } else {
            dest = OutputStream.toMemory()
            tempFilePath = nil
        }

        return (dest, tempFilePath)
    }

    func multipartFormDataStream(boundary: String, forceWriteToFile: Bool = false) throws -> Either<Data, URL> {
        guard !isEmpty else {
            return .left(Data())
        }

        let (dest, tempFilePath) = try multipartFormDestination(forceWriteToFile: forceWriteToFile)

        // Build the form content
        do {
            dest.open()
            defer { dest.close() }

            writeMultipartFormData(destination: dest, boundary: boundary)
        }

        // Return the result as `InputStream`
        if let tempFilePath {
            return .right(URL(fileURLWithPath: tempFilePath))
        }

        if let data = dest.property(forKey: .dataWrittenToMemoryStreamKey) as? Data {
            return .left(data)
        }

        throw MultipartFormError.impossible
    }

    private func writeMultipartFormData(destination dest: OutputStream, boundary: String) {
        for field in self {
            dest.writeMultipartForm(boundary: boundary, isEnd: false)

            // Write headers
            var disposition = ["form-data", "name=\"\(field.name)\""]
            if let filename = field.filename {
                disposition += ["filename=\"\(filename)\""]
            }
            dest.writeMultipartFormHeader(name: "Content-Disposition", value: disposition.joined(separator: "; "))

            if let mimeType = field.mimeType {
                dest.writeMultipartFormHeader(name: "Content-Type", value: mimeType)
            }

            // Write a linebreak between header and content
            dest.writeMultipartFormLineBreak()

            // Write content
            field.inputStream.open()
            defer {
                field.inputStream.close()
            }
            let maxLength = 1024
            var buffer = [UInt8](repeating: 0, count: maxLength)
            while field.inputStream.hasBytesAvailable {
                let bytes = field.inputStream.read(&buffer, maxLength: maxLength)
                dest.write(data: Data(bytesNoCopy: &buffer, count: bytes, deallocator: .none))
            }

            dest.writeMultipartFormLineBreak()
        }

        dest.writeMultipartForm(boundary: boundary, isEnd: true)
    }
}

private let multipartFormDataLineBreak = "\r\n"
private extension OutputStream {
    func write(data: Data) {
        let count = data.count
        guard count > 0 else { return }

        _ = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            write(ptr.bindMemory(to: Int8.self).baseAddress!, maxLength: count)
        }
    }

    func writeMultipartForm(lineContent: String) {
        write(data: "\(lineContent)\(multipartFormDataLineBreak)".data(using: .utf8)!)
    }

    func writeMultipartFormLineBreak() {
        write(data: multipartFormDataLineBreak.data(using: .utf8)!)
    }

    func writeMultipartFormHeader(name: String, value: String) {
        writeMultipartForm(lineContent: "\(name): \(value)")
    }

    func writeMultipartForm(boundary: String, isEnd: Bool) {
        if isEnd {
            writeMultipartForm(lineContent: "--\(boundary)--")
        } else {
            writeMultipartForm(lineContent: "--\(boundary)")
        }
    }
}
