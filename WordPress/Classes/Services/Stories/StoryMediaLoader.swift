import Foundation
import Kanvas

final class StoryMediaLoader {

    typealias Output = (CameraSegment, Data?)

    private var completion: (([Output]) -> Void)?

    private var downloadTasks: [ImageDownloaderTask] = []
    private var results: [Output?] = [] {
        didSet {
            if results.contains(where: { $0 == nil }) == false {
                completion?(results.compactMap { $0 })
                results = []
            }
        }
    }

    private let mediaUtility = EditorMediaUtility()

    func download(files: [MediaFile], for post: AbstractPost, completion: @escaping ([Output]) -> Void) {

        self.completion = completion
        results = [Output?](repeating: nil, count: files.count)
        downloadTasks = []

        let coreDataStack = ContextManager.shared
        let mediaRepository = MediaRepository(coreDataStack: coreDataStack)
        let blogID = TaggedManagedObjectID(saved: post.blog)
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

            Task { @MainActor [weak self] in
                let media: Media
                do {
                    let mediaID = try await mediaRepository.getMedia(withID: NSNumber(value: Double(file.id) ?? 0), in: blogID)
                    media = try coreDataStack.mainContext.existingObject(with: mediaID)
                } catch {
                    DDLogWarn("Stories media fetch error \(error)")
                    return
                }

                guard let self = self else { return }
                let mediaType = media.mediaType
                switch mediaType {
                case .image:
                    let size = media.pixelSize()
                    if let url = URL(string: file.url) {
                        let task = self.mediaUtility.downloadImage(from: url, size: size, scale: 1, post: post, success: { [weak self] image in
                            DispatchQueue.main.async {
                                self?.results[idx] = (CameraSegment.image(image, nil, nil, Kanvas.MediaInfo(source: .kanvas_camera)), nil)
                            }
                        }, onFailure: { error in
                            DDLogWarn("Failed Stories image download: \(error)")
                        })
                        self.downloadTasks.append(task)
                    }
                case .video:
                    EditorMediaUtility.fetchRemoteVideoURL(for: media, in: post, withToken: true) { [weak self] result in
                        switch result {
                        case .success((let videoURL)):
                            DispatchQueue.main.async {
                                self?.results[idx] = (CameraSegment.video(videoURL, nil), nil)
                            }
                        case .failure(let error):
                            DDLogWarn("Failed stories video download: \(error)")
                        }
                    }
                default:
                    DDLogWarn("Unexpected Stories media type: \(mediaType)")
                }
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
