import Foundation
import Aztec

class GutenbergVideoPressUploadProcessor: Processor {

    let mediaUploadID: Int32
    let serverMediaID: Int
    let videoPressGUID: String
    var videoPressURL: String = ""

    private enum VideoPressBlockKeys: String {
        case name = "wp:videopress/video"
        case id
        case guid
        case resizeToParent
        case cover
        case autoplay
        case controls
        case loop
        case muted
        case playsinline
        case poster
        case preload
        case seekbarColor
        case seekbarPlayedColor
        case seekbarLoadingColor
        case useAverageColor
    }

    private enum VideoPressURLQueryParams: String {
        case resizeToParent
        case cover
        case autoPlay
        case controls
        case loop
        case muted
        case persistVolume
        case playsinline
        case posterUrl
        case preloadContent
        case sbc
        case sbpc
        case sblc
        case useAverageColor
    }

    init(mediaUploadID: Int32, serverMediaID: Int, videoPressGUID: String) {
        self.mediaUploadID = mediaUploadID
        self.serverMediaID = serverMediaID
        self.videoPressGUID = videoPressGUID
    }

    lazy var videoPressHtmlProcessor = HTMLProcessor(for: "figure", replacer: { (figure) in
        var attributes = figure.attributes
        var html = "<figure "
        let attributeSerializer = ShortcodeAttributeSerializer()
        html += attributeSerializer.serialize(figure.attributes)
        html += "><div class=\"jetpack-videopress-player__wrapper\">"
        html += "\n\(self.videoPressURL.escapeHtmlNamedEntities())\n"
        html += "</div></figure>"
        return html
    })

    lazy var videoPressBlockProcessor = GutenbergBlockProcessor(for: VideoPressBlockKeys.name.rawValue, replacer: { videoPressBlock in
        guard let mediaID = videoPressBlock.attributes[VideoPressBlockKeys.id.rawValue] as? Int, mediaID == self.mediaUploadID else {
            return nil
        }
        var block = "<!-- \(VideoPressBlockKeys.name) "
        var attributes = videoPressBlock.attributes
        attributes[VideoPressBlockKeys.id.rawValue] = self.serverMediaID
        attributes[VideoPressBlockKeys.guid.rawValue] = self.videoPressGUID
        if let jsonData = try? JSONSerialization.data(withJSONObject: attributes, options: .sortedKeys),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            block += jsonString
        }
        block += " -->"

        self.videoPressURL = self.getVideoPressURL(attributes)
        block += self.videoPressHtmlProcessor.process(videoPressBlock.content)

        block += "<!-- /\(VideoPressBlockKeys.name) -->"
        return block
    })

    /// The VideoPress URL is built using the same logic we have in Jetpack:
    /// https://github.com/Automattic/jetpack/blob/b1b826ab38690c5fad18789301ac81297a458878/projects/packages/videopress/src/client/lib/url/index.ts#L19-L67
    ///
    /// In order to have a cleaner URL, we only set the options differing from the default VideoPress player settings:
    /// - Autoplay: Turned OFF by default.
    /// - Controls: Turned ON by default.
    /// - Loop: Turned OFF by default.
    /// - Muted: Turned OFF by default.
    /// - Plays Inline: Turned OFF by default.
    /// - Poster: No image by default.
    /// - Preload: Metadata by default.
    /// - SeekbarColor: No color by default.
    /// - SeekbarPlayerColor: No color by default.
    /// - SeekbarLoadingColor: No color by default.
    /// - UseAverageColor: Turned ON by default.
    func getVideoPressURL(_ attributes: [String: Any]) -> String {
        // Setting default values
        var options: [URLQueryItem] = [
            URLQueryItem(name: VideoPressURLQueryParams.resizeToParent.rawValue, value: true.stringLiteral),
            URLQueryItem(name: VideoPressURLQueryParams.cover.rawValue, value: true.stringLiteral),
        ]

        if let autoplay = attributes[VideoPressBlockKeys.autoplay.rawValue] as? Bool, autoplay == true {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.autoPlay.rawValue, value: autoplay.stringLiteral))
        }
        if let controls = attributes[VideoPressBlockKeys.controls.rawValue] as? Bool, controls == false {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.controls.rawValue, value: controls.stringLiteral))
        }
        if let loop = attributes[VideoPressBlockKeys.loop.rawValue] as? Bool, loop == true {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.loop.rawValue, value: loop.stringLiteral))
        }
        if let muted = attributes[VideoPressBlockKeys.muted.rawValue] as? Bool, muted == true {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.muted.rawValue, value: muted.stringLiteral))
            options.append(URLQueryItem(name: VideoPressURLQueryParams.persistVolume.rawValue, value: false.stringLiteral))
        }
        if let playinline = attributes[VideoPressBlockKeys.playsinline.rawValue] as? Bool, playinline == true {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.playsinline.rawValue, value: playinline.stringLiteral))
        }
        if let poster = attributes[VideoPressBlockKeys.poster.rawValue] as? String, !poster.isEmpty {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.posterUrl.rawValue, value: poster))
        }
        if let preload = attributes[VideoPressBlockKeys.preload.rawValue] as? String, !preload.isEmpty {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.preloadContent.rawValue, value: preload))
        }
        else {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.preloadContent.rawValue, value: "metadata"))
        }
        if let seekbarColor = attributes[VideoPressBlockKeys.seekbarColor.rawValue] as? String, !seekbarColor.isEmpty {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.sbc.rawValue, value: seekbarColor))
        }
        if let seekbarPlayedColor = attributes[VideoPressBlockKeys.seekbarPlayedColor.rawValue] as? String, !seekbarPlayedColor.isEmpty {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.sbpc.rawValue, value: seekbarPlayedColor))
        }
        if let seekbarLoadingColor = attributes[VideoPressBlockKeys.seekbarLoadingColor.rawValue] as? String, !seekbarLoadingColor.isEmpty {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.sblc.rawValue, value: seekbarLoadingColor))
        }
        if let useAverageColor = attributes[VideoPressBlockKeys.useAverageColor.rawValue] as? Bool {
            if useAverageColor == true {
                options.append(URLQueryItem(name: VideoPressURLQueryParams.useAverageColor.rawValue, value: useAverageColor.stringLiteral))
            }
        }
        // Adding `useAverageColor` param as its default value is true
        else {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.useAverageColor.rawValue, value: true.stringLiteral))
        }

        guard let url = URL(string: "https://videopress.com/v/\(self.videoPressGUID)"), var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return ""
        }
        urlComponents.queryItems = options
        guard
            let query = urlComponents.query,
            /// In web, the query parameters are encoded using `encodeURIComponent` that percent encodes reserved characters (like `/` and `:`) that are not strictly necessary to be encoded based on RFC 3986.
            /// In the spirit of generating an URL with the same encoding, we encode using `urlHostAllowed` which percent encodes all reserved characters.
            ///
            /// References:
            /// - https://en.wikipedia.org/wiki/URL_encoding#Reserved_characters
            /// - https://www.ietf.org/rfc/rfc3986.txt
            /// - https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent
            /// - https://github.com/WordPress/gutenberg/blob/1dfec0ab5f0977dcce2722bdfbe823926903e2a6/packages/url/src/build-query-string.js#L53
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            return url.absoluteString
        }
        return "\(url.absoluteString)?\(encodedQuery)"
    }

    func process(_ text: String) -> String {
        return videoPressBlockProcessor.process(text)
    }
}
