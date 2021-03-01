import Kanvas

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

    func download(files: [MediaFile], for post: AbstractPost, completion: @escaping ([Output]) -> Void) {

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
                DDLogError("Error unarchiving \(file.url) - \(error)")
            }

            service.getMediaWithID(NSNumber(value: Double(file.id) ?? 0), in: post.blog, success: { [weak self] media in
                guard let self = self else { return }
                let mediaType = media.mediaType
                switch mediaType {
                case .image:
                    let size = media.pixelSize()
                    if let url = URL(string: file.url) {
                        let task = self.mediaUtility.downloadImage(from: url, size: size, scale: 1, post: post, success: { [weak self] image in
                            self?.queue.async {
                                self?.results[idx] = (CameraSegment.image(image, nil, nil, Kanvas.MediaInfo(source: .kanvas_camera)), nil)
                            }
                        }, onFailure: { error in
                            DDLogWarn("Failed Stories image download: \(error)")
                        })
                        self.downloadTasks.append(task)
                    }
                case .video:
                    EditorMediaUtility.fetchRemoteVideoURL(for: media, in: post) { [weak self] result in
                        switch result {
                        case .success((let videoURL, _)):
                            self?.queue.async {
                                self?.results[idx] = (CameraSegment.video(videoURL, nil), nil)
                            }
                        case .failure(let error):
                            DDLogWarn("Failed stories video download: \(error)")
                        }
                    }
                default:
                    DDLogWarn("Unexpected Stories media type: \(mediaType)")
                }

            }) { (error) in
                DDLogWarn("Stories media fetch error \(error)")
            }
        }
    }

    func unarchive(file: MediaFile) throws -> (CameraSegment, Data?)? {
        if let archiveURL = StoryPoster.filePath?.appendingPathComponent(file.id) {
            return try CameraController.unarchive(archiveURL)
        } else {
            return nil
        }
    }

    func cancel() {
        downloadTasks.forEach({ $0.cancel() })
    }
}
