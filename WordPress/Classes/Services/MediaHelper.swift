class MediaHelper: NSObject {

    @objc(updateMedia:withRemoteMedia:)
    static func update(media: Media, with remoteMedia: RemoteMedia) {
        if media.mediaID != remoteMedia.mediaID {
            media.mediaID =  remoteMedia.mediaID
        }
        if media.remoteURL != remoteMedia.url?.absoluteString {
            media.remoteURL = remoteMedia.url?.absoluteString
        }
        if media.remoteLargeURL != remoteMedia.largeURL?.absoluteString {
            media.remoteLargeURL = remoteMedia.largeURL?.absoluteString
        }
        if media.remoteMediumURL != remoteMedia.mediumURL?.absoluteString {
            media.remoteMediumURL = remoteMedia.mediumURL?.absoluteString
        }
        if remoteMedia.date != nil && remoteMedia.date != media.creationDate {
            media.creationDate = remoteMedia.date
        }
        if media.filename != remoteMedia.file {
            media.filename = remoteMedia.file
        }
        if let mimeType = remoteMedia.mimeType, !mimeType.isEmpty {
            media.setMediaType(forMimeType: mimeType)
        } else if let fileExtension = remoteMedia.extension, !fileExtension.isEmpty {
            media.setMediaType(forFilenameExtension: fileExtension)
        }
        if media.title != remoteMedia.title {
            media.title = remoteMedia.title
        }
        if media.caption != remoteMedia.caption {
            media.caption = remoteMedia.caption
        }
        if media.desc != remoteMedia.descriptionText {
            media.desc = remoteMedia.descriptionText
        }
        if media.alt != remoteMedia.alt {
            media.alt = remoteMedia.alt
        }
        if media.height != remoteMedia.height {
            media.height = remoteMedia.height
        }
        if media.width != remoteMedia.width {
            media.width = remoteMedia.width
        }
        if media.shortcode != remoteMedia.shortcode {
            media.shortcode = remoteMedia.shortcode
        }
        if media.videopressGUID != remoteMedia.videopressGUID {
            media.videopressGUID = remoteMedia.videopressGUID
        }
        if media.length != remoteMedia.length {
            media.length = remoteMedia.length
        }
        // TODO: The value keeps changing every time you reload media for some reason
        if media.remoteThumbnailURL != remoteMedia.remoteThumbnailURL {
            media.remoteThumbnailURL = remoteMedia.remoteThumbnailURL
        }
        if media.postID != remoteMedia.postID {
            media.postID = remoteMedia.postID
        }
        if media.remoteStatus != .sync {
            media.remoteStatus = .sync
        }
        if media.error != nil {
            media.error = nil
        }

    }

    static func advertiseImageOptimization(completion: @escaping (() -> Void)) {
        guard MediaSettings().advertiseImageOptimization else {
            completion()
            return
        }

        let title = NSLocalizedString("Keep optimizing images?",
                                        comment: "Title of an alert informing users to enable image optimization in uploads.")
        let message = NSLocalizedString("Image optimization shrinks images for quicker uploading.\n\nBy default it's enabled but you can change this any time in app settings.",
                                        comment: "Message of an alert informing users to enable image optimization in uploads.")
        let turnOffTitle = NSLocalizedString("No, turn off", comment: "Title of button for turning off image optimization, displayed in the alert informing users to enable image optimization in uploads.")
        let leaveOnTitle = NSLocalizedString("Yes, leave on", comment: "Title of button for leaving on image optimization, displayed in the alert informing users to enable image optimization in uploads.")

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: turnOffTitle, style: .default) { _ in
            MediaSettings().imageOptimizationSetting = false
            WPAnalytics.track(.appSettingsOptimizeImagesPopupTapped, properties: ["option": "off" as
                                                                                     AnyObject])
            completion()
        })
        alert.addAction(UIAlertAction(title: leaveOnTitle, style: .default) { _ in
            MediaSettings().imageOptimizationSetting = true
            WPAnalytics.track(.appSettingsOptimizeImagesPopupTapped, properties: ["option": "on" as
                                                                                     AnyObject])
            completion()
        })
        alert.presentFromRootViewController()

        MediaSettings().advertiseImageOptimization = false
    }
}

extension Media {
    /// Downloads remote data for the given media to a temporary directory. The
    /// directory is cleared every time you launch the app.
    @MainActor static func downloadRemoteData(for selection: [Media], blog: Blog) async throws -> [URL] {
        let session = URLSession(configuration: {
            let configuration = URLSessionConfiguration.default
            configuration.urlCache = nil // Caching in a temporary directory
            return configuration
        }())
        let authenticator = MediaRequestAuthenticator()
        let host = MediaHost(with: blog)
        let temporaryDirectory = Media.remoteDataTemporaryDirectoryURL

        var output: [URL] = []
        for media in selection {
            // Try local URL
            if let localURL = media.absoluteLocalURL,
               FileManager.default.fileExists(at: localURL) {
                output.append(localURL)
                continue
            }

            // Try remote URL
            guard let blogID = blog.dotComID?.intValue,
                  let mediaID = media.mediaID?.intValue,
                  let remoteURL = media.remoteURL.flatMap(URL.init) else {
                throw URLError(.unknown)
            }

            // Check if we downloaded it before during this session
            let filename = "\(blogID)–\(mediaID).\(remoteURL.pathExtension)"
            let copyURL = temporaryDirectory.appendingPathComponent(filename, isDirectory: false)
            if FileManager.default.fileExists(at: copyURL) {
                output.append(copyURL)
                continue
            }

            let request = try await authenticator.authenticatedRequest(for: remoteURL, host: host)
            let (fileURL, response) = try await session.download(for: request)
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
                  (200..<400).contains(statusCode) else {
                throw URLError(.unknown)
            }

            try FileManager.default.copyItem(at: fileURL, to: copyURL)
            output.append(copyURL)
        }

        return output
    }

    static func removeTemporaryData() {
        _ =  remoteDataTemporaryDirectoryURL
    }

    private static let remoteDataTemporaryDirectoryURL: URL = {
        var tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("org.automattic.RemoteMediaTEmporaryDirectory", isDirectory: true)
        // Remove data from the previous sessions.
        try? FileManager.default.removeItem(at: tempDirectoryURL)
        try? FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true)
        return tempDirectoryURL
    }()
}
