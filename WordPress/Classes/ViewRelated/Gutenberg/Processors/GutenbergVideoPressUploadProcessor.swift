import Foundation
import Aztec

class GutenbergVideoPressUploadProcessor: Processor {

    let mediaUploadID: Int32
    let serverMediaID: Int
    let videoPressGUID: String
    var videoPressURL: String = ""

    private struct VideoPressBlockKeys {
        static var name = "wp:videopress/video"
        static var id = "id"
        static var guid = "guid"
        static var resizeToParent = "resizeToParent"
        static var cover = "cover"
        static var autoplay = "autoplay"
        static var controls = "controls"
        static var loop = "loop"
        static var muted = "muted"
        static var playsinline = "playsinline"
        static var poster = "poster"
        static var preload = "preload"
        static var seekbarColor = "seekbarColor"
        static var seekbarPlayedColor = "seekbarPlayedColor"
        static var seekbarLoadingColor = "seekbarLoadingColor"
        static var useAverageColor = "useAverageColor"
    }

    private struct VideoPressURLQueryParams {
        static var resizeToParent = "resizeToParent"
        static var cover = "cover"
        static var autoPlay = "autoPlay"
        static var controls = "controls"
        static var loop = "loop"
        static var muted = "muted"
        static var persistVolume = "persistVolume"
        static var playsinline = "playsinline"
        static var posterUrl = "posterUrl"
        static var preloadContent = "preloadContent"
        static var sbc = "sbc"
        static var sbpc = "sbpc"
        static var sblc = "sblc"
        static var useAverageColor = "useAverageColor"
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

    lazy var videoPressBlockProcessor = GutenbergBlockProcessor(for: VideoPressBlockKeys.name, replacer: { videoPressBlock in
        guard let mediaID = videoPressBlock.attributes[VideoPressBlockKeys.id] as? Int, mediaID == self.mediaUploadID else {
            return nil
        }
        var block = "<!-- \(VideoPressBlockKeys.name) "
        var attributes = videoPressBlock.attributes
        attributes[VideoPressBlockKeys.id] = self.serverMediaID
        attributes[VideoPressBlockKeys.guid] = self.videoPressGUID
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
            URLQueryItem(name: VideoPressURLQueryParams.resizeToParent, value: true.stringLiteral),
            URLQueryItem(name: VideoPressURLQueryParams.cover, value: true.stringLiteral),
        ]

        if let autoplay = attributes[VideoPressBlockKeys.autoplay] as? Bool, autoplay == true {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.autoPlay, value: autoplay.stringLiteral))
        }
        if let controls = attributes[VideoPressBlockKeys.controls] as? Bool, controls == false {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.controls, value: controls.stringLiteral))
        }
        if let loop = attributes[VideoPressBlockKeys.loop] as? Bool, loop == true {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.loop, value: loop.stringLiteral))
        }
        if let muted = attributes[VideoPressBlockKeys.muted] as? Bool, muted == true {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.muted, value: muted.stringLiteral))
            options.append(URLQueryItem(name: VideoPressURLQueryParams.persistVolume, value: false.stringLiteral))
        }
        if let playinline = attributes[VideoPressBlockKeys.playsinline] as? Bool, playinline == true {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.playsinline, value: playinline.stringLiteral))
        }
        if let poster = attributes[VideoPressBlockKeys.poster] as? String, !poster.isEmpty {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.posterUrl, value: poster))
        }
        if let preload = attributes[VideoPressBlockKeys.preload] as? String, !preload.isEmpty {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.preloadContent, value: preload))
        }
        else {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.preloadContent, value: "metadata"))
        }
        if let seekbarColor = attributes[VideoPressBlockKeys.seekbarColor] as? String, !seekbarColor.isEmpty {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.sbc, value: seekbarColor))
        }
        if let seekbarPlayedColor = attributes[VideoPressBlockKeys.seekbarPlayedColor] as? String, !seekbarPlayedColor.isEmpty {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.sbpc, value: seekbarPlayedColor))
        }
        if let seekbarLoadingColor = attributes[VideoPressBlockKeys.seekbarLoadingColor] as? String, !seekbarLoadingColor.isEmpty {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.sblc, value: seekbarLoadingColor))
        }
        if let useAverageColor = attributes[VideoPressBlockKeys.useAverageColor] as? Bool {
            if useAverageColor == true {
                options.append(URLQueryItem(name: VideoPressURLQueryParams.useAverageColor, value: useAverageColor.stringLiteral))
            }
        }
        // Adding `useAverageColor` param as its default value is true
        else {
            options.append(URLQueryItem(name: VideoPressURLQueryParams.useAverageColor, value: true.stringLiteral))
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
