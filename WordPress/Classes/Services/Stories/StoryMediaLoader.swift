class StoryMediaLoader {

    enum Output {
        case image(UIImage)
        case video(URL)
    }

    var completion: (([Output]) -> Void)?

    var downloadTasks: [ImageDownloaderTask] = []
    var results: [Output?] = []

    private let mediaUtility = EditorMediaUtility()
    private let queue = DispatchQueue.global(qos: .userInitiated)

    func download(files: [StoryPoster.MediaFile], for post: AbstractPost, completion: @escaping ([Output]) -> Void) {

        self.completion = completion
        results = [Output?](repeating: nil, count: files.count)
        downloadTasks = []

        let service = MediaService(managedObjectContext: ContextManager.shared.mainContext)
        files.enumerated().forEach { (idx, file) in
            service.getMediaWithID(NSNumber(value: file.id), in: post.blog, success: { [weak self] media in
                guard let self = self else { return }
                let mediaType = media.mediaType
                switch mediaType {
                case .image:
                    let size = media.pixelSize()
                    let task = self.mediaUtility.downloadImage(from: URL(string: file.url)!, size: size, scale: 1, post: post, success: { [weak self] image in
                        self?.queue.async {
                            self?.results[idx] = .image(image)
                            self?.completed()
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
                                    self?.results[idx] = .video(videoURL)
//                                }
                                self?.completed()
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

    private func completed() {
        if results.contains(where: { $0 == nil }) == false {
            completion?(results.compactMap { $0 })
        }
    }

    func cancel() {
        downloadTasks.forEach({ $0.cancel() })
    }
}
