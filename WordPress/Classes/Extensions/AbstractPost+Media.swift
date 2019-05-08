
extension AbstractPost {

    func fetchRemoteVideoURL(for media: Media, completion: @escaping ( Result<(videoURL: URL, posterURL: URL?)> ) -> Void) {
        guard let videoPressID = media.videopressGUID else {
            //the site can be a self-hosted site if there's no videopressGUID
            if let videoURLString = media.remoteURL,
                let videoURL = URL(string: videoURLString) {
                completion(Result.success((videoURL: videoURL, posterURL: nil)))
            } else {
                DDLogError("Unable to find remote video URL for video with upload ID = \(media.uploadID).")
                completion(Result.error(NSError()))
            }
            return
        }
        let mediaService = MediaService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        mediaService.getMediaURL(fromVideoPressID: videoPressID, in: self.blog, success: { (videoURLString, posterURLString) in
            guard let videoURL = URL(string: videoURLString) else {
                completion(Result.error(NSError()))
                return
            }
            var posterURL: URL?
            if let validPosterURLString = posterURLString, let url = URL(string: validPosterURLString) {
                posterURL = url
            }
            completion(Result.success((videoURL: videoURL, posterURL: posterURL)))
        }, failure: { (error) in
            DDLogError("Unable to find information for VideoPress video with ID = \(videoPressID). Details: \(error.localizedDescription)")
            completion(Result.error(error))
        })
    }
}
