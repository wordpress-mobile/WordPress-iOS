import Foundation

extension InputStream {
    func read() -> Data? {
        open()

        let bufferSize: Int = 64
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        var data = Data()

        while hasBytesAvailable {
            let readData = read(buffer, maxLength: bufferSize)
            data.append(buffer, count: readData)
        }

        buffer.deallocate()
        close()

        return data
    }
}
