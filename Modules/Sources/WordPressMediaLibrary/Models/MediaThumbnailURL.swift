import Foundation
import WordPressAPI
import WordPressAPIInternal

/// Picks a thumbnail URL from `ImageMediaDetails.sizes`, falling back through
/// a preference list and finally to `sourceUrl`. The 4-per-row phone grid
/// renders ~270px cells at @3x — `medium` (default 300px) is the closest
/// well-known size; `thumbnail` (150px) covers the case where only the small
/// image has been generated server-side.
enum MediaThumbnailURL {
    private static let preferenceOrder = ["medium", "medium_large", "large", "thumbnail"]

    static func pick(from imageDetails: ImageMediaDetails, sourceUrl: String) -> URL? {
        for key in preferenceOrder {
            if let scaled = imageDetails.sizes?[key], let url = URL(string: scaled.sourceUrl) {
                return url
            }
        }
        return URL(string: sourceUrl)
    }
}
