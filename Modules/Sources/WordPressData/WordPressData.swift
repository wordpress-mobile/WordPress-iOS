@_exported import WordPressDataObjC

public let modelURL: URL = {
    guard let url = Bundle.module.url(forResource: "WordPress", withExtension: "momd") else {
        fatalError("Cannot find model file.")
    }
    return url
}()

public func urlForModel(name: String, in directory: String?) -> URL? {
    let bundle = Bundle(for: TemporaryDummyClassToPickUpModule.self)
    var url = bundle.url(forResource: name, withExtension: "mom", subdirectory: directory)

    if url != nil {
        return url
    }

    let momdPaths = bundle.paths(forResourcesOfType: "momd", inDirectory: directory)
    momdPaths.forEach { (path) in
        if url != nil {
            return
        }
        url = bundle.url(forResource: name, withExtension: "mom", subdirectory: URL(fileURLWithPath: path).lastPathComponent)
    }

    return url
}

private class TemporaryDummyClassToPickUpModule {}
