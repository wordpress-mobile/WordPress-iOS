import GiphyCoreSDK

/// Encapsulates search parameters (text, pagination, etc)
struct GiphySearchParams {
    let text: String
    let pageable: Pageable?

    init(text: String?, pageable: Pageable?) {
        self.text = text ?? ""
        self.pageable = pageable
    }
}

struct GiphyService {
    static let giphy: GPHClient = {
        GiphyCore.configure(apiKey: ApiCredentials.giphyAppId())
        return GiphyCore.shared
    }()

    func search(params: GiphySearchParams, completion: @escaping (GiphyResultsPage) -> Void) {
        GiphyService.giphy.search(params.text, rating: .ratedG) { (response, error) in
            DispatchQueue.main.async {
                if let _ = error as NSError? {
                    completion(GiphyResultsPage.empty())
                    return
                }

                if let response = response, let data = response.data {
                    let media = data.compactMap({ GiphyMedia(gphMedia: $0) })

                    completion(GiphyResultsPage(results: media))
                } else {
                    completion(GiphyResultsPage.empty())
                }
            }
        }
    }
}

extension GiphyMedia {
    convenience init?(gphMedia: GPHMedia) {
        guard let image = gphMedia.images?.fixedHeightStill,
            let imageURL = image.gifUrl  else {
            return nil
        }

        self.init(id: gphMedia.id,
                  url: imageURL,
                  size: CGSize(width: image.width, height: image.height),
                  date: gphMedia.updateDate)
    }
}
