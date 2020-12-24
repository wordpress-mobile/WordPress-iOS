import KanvasCamera

class StoryMediaLoader {

    typealias Output = (CameraSegment, Data?)

    var completion: (([Output]) -> Void)?

    var downloadTasks: [ImageDownloaderTask] = []
    var results: [Output?] = [] {
        didSet {
            if results.contains(where: { $0 == nil }) == false {
                completion?(results.compactMap { $0 })
                results = []
            }
        }
    }

    private let mediaUtility = EditorMediaUtility()
    private let queue = DispatchQueue.global(qos: .userInitiated)

    func download(files: [StoryPoster.MediaFile], for post: AbstractPost, completion: @escaping ([Output]) -> Void) {

        self.completion = completion
        results = [Output?](repeating: nil, count: files.count)
        downloadTasks = []

        let service = MediaService(managedObjectContext: ContextManager.shared.mainContext)
        files.enumerated().forEach { (idx, file) in

            do {
                let archive = try unarchive(file: file)

                if let archive = archive {

                    let validFile: Bool
                    let segment = archive.0

                    switch segment {
                    case .image:
                        validFile = true
                    case .video(let url, _):
                        validFile = FileManager.default.fileExists(atPath: url.path)
                    }

                    if validFile {
                        results[idx] = archive
                        return
                    }
                }
            } catch let error {
                print("Error unarchiving \(file.url) - \(error)")
            }

            service.getMediaWithID(NSNumber(value: file.id), in: post.blog, success: { [weak self] media in
                guard let self = self else { return }
                let mediaType = media.mediaType
                switch mediaType {
                case .image:
                    let size = media.pixelSize()
                    let task = self.mediaUtility.downloadImage(from: URL(string: file.url)!, size: size, scale: 1, post: post, success: { [weak self] image in
                        let source = CGImageSourceCreateWithDataProvider(image.cgImage!.dataProvider!, nil)!
                        self?.queue.async {
                            self?.results[idx] = (CameraSegment.image(source, nil, nil, KanvasCamera.MediaInfo(source: .kanvas_camera)), nil)
                        }
                    }, onFailure: { error in
                        print("Failed image download")
                    })
                    self.downloadTasks.append(task)
                case .video:
                    //videoAssetWithCompletionHandler
                    EditorMediaUtility.fetchRemoteVideoURL(for: media, in: post) { [weak self] result in
                        switch result {
                        case .success((let videoURL, _)):
                            self?.queue.async {
//                                if let url = url {
                                    //TODO: Move video file?
                                    self?.results[idx] = (CameraSegment.video(videoURL, nil), nil)
//                                }
                            }
                        case .failure(let error):
                            print("Failed video download \(error)")
                        }
                    }
                default:
                    print("Unexpected Media Type")
                }

            }) { (error) in
                print("Media fetch error \(error)")
            }
        }
    }

    func unarchive(file: StoryPoster.MediaFile) throws -> (CameraSegment, Data?)? {
        let archiveURL = StoryPoster.filePath.appendingPathComponent("\(Int(file.id))")
        return try CameraController.unarchive(archiveURL)
    }

    func cancel() {
        downloadTasks.forEach({ $0.cancel() })
    }
}
