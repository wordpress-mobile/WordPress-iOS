
import Foundation

@testable import WordPress

struct TenorMockDataHelper {
    static let mockMedia: TenorMedia = {
        let data = TenorReponseData.validSearchResponse
        let parser = TenorResponseParser<TenorGIF>()
        try! parser.parse(data)

        return TenorMedia(tenorGIF: parser.results!.first!)!
    }()

    static let mockMediaList: [TenorMedia] = {
        let media = TenorMockDataHelper.mockMedia
        return [media, media]
    }()

    static func createMockMedia(withId id: String) -> TenorMedia {
        let media = TenorMockDataHelper.mockMedia
        return TenorMedia(id: id,
                          name: media.name,
                          images: media.images,
                          date: media.updatedDate)
    }
}
