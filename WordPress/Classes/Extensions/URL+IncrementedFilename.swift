import Foundation

extension URL {

    /// Returns a URL with an incremented file name, if a file already exists at the given URL
    ///
    /// Previously seen in MediaService.m within urlForMediaWithFilename:andExtension:
    ///
    func incrementedFilename() -> URL {
        var url = self
        let pathExtension = url.pathExtension
        let filename = url.deletingPathExtension().lastPathComponent
        var index = 1
        let fileManager = FileManager.default
        while fileManager.fileExists(atPath: url.path) {
            let incrementedName = "\(filename)-\(index)"
            url.deleteLastPathComponent()
            url.appendPathComponent(incrementedName, isDirectory: false)
            url.appendPathExtension(pathExtension)
            index += 1
        }
        return url
    }
}
