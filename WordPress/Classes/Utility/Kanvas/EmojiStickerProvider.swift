import KanvasCamera

class EmojiStickerProvider {

    private weak var delegate: StickerProviderDelegate?

    enum EmojiType: CaseIterable {
        case emoticons
        case symbols
        case transport
        case regionalFlags

        var range: ClosedRange<Int> {
            switch self {
            case .emoticons:
                return 0x1F600...0x1F64F
            case .symbols:
                return 0x1F300...0x1F5FF
            case .transport:
                return 0x1F680...0x1F6FF
            case .regionalFlags:
                return 0x1F1E6...0x1F1FF
            }
        }
    }
}

extension EmojiStickerProvider: StickerProvider {
    func getStickerTypes() {
        let stickerTypes: [StickerType] = EmojiType.allCases.enumerated().map { (idx, type) in
            let emoji: [String] = type.range.compactMap { i in
                if let scalar = UnicodeScalar(i) {
                    let unicode = Character(scalar)
                    if unicode.unicodeAvailable() {
                        return String(scalar)
                    }
                }
                return nil
            }
            let stickers: [Sticker] = emoji.map { s -> Sticker in
                let urlString = "http://wordpress-emoji.com/\(s)"
                let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? urlString
                return Sticker(id: s, imageUrl: escapedString)
            }
            return StickerType(id: "\(idx)", imageUrl: "http://wordpress-emoji.com/", stickers: stickers)
        }
        delegate?.didLoadStickerTypes(stickerTypes)
    }

    func setDelegate(delegate: StickerProviderDelegate) {
        self.delegate = delegate
    }

    func loader() -> KanvasStickerLoader? {
        return KanvasEmojiLoader()
    }
}

class KanvasEmojiLoader: KanvasStickerLoader {
    let renderingQueue = DispatchQueue(label: "KanvasEmojiQueue", qos: .userInteractive)

    func loadSticker(at imageURL: URL, imageView: UIImageView?, completion: @escaping (UIImage?, Error?) -> Void) -> KanvasCancelable {
        let string = imageURL.lastPathComponent.removingPercentEncoding ?? ""
        let character = Character(string)

        let workItem = DispatchWorkItem {
            if let data = character.png(ofSize: 125) {
                let image = UIImage(data: data)
                DispatchQueue.main.async {
                    imageView?.image = image
                    completion(image, nil)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil, nil)
                }
            }
        }

        renderingQueue.async(execute: workItem)
        return workItem
    }
}

extension DispatchWorkItem: KanvasCancelable {
}

fileprivate extension Character {
    private static let refUnicodeSize: CGFloat = 8
    private static let refUnicodePng =
        Character("\u{1fff}").png(ofSize: Character.refUnicodeSize)

    func png(ofSize fontSize: CGFloat) -> Data? {
        let attributes = [NSAttributedString.Key.font:
            UIFont.systemFont(ofSize: fontSize)]
        let charStr = String(self)
        let size = charStr.size(withAttributes: attributes)

        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.pngData { context in
            charStr.draw(at: CGPoint(x: 0, y: 0), withAttributes: attributes)
        }
    }

//    func vector(ofSize fontSize: CGFloat) -> Data? {
//
//        let attributes = [NSAttributedString.Key.font:
//            UIFont.systemFont(ofSize: fontSize)]
//        let charStr = "\(self)" as NSString
//        let size = charStr.size(withAttributes: attributes)
//
//        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: size))
//        return renderer.pdfData { context in
//            charStr.draw(at: CGPoint(x: 0,y :0), withAttributes: attributes)
//        }
//    }

//    func vector() {
//        guard
//            let pdf = PDFDocument(data: data),
//            let pdfPage = pdf.page(at: 0),
//            let pageRef = pdfPage.pageRef
//        else { return nil }
//
//        let pageRect = pageRef.getBoxRect(.mediaBox)
//        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
//        let img = renderer.image { ctx in
//            UIColor.clear.set()
//            ctx.fill(pageRect)
//
//            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
//            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
//
//            ctx.cgContext.drawPDFPage(pageRef)
//        }
//        return img
//    }

    func unicodeAvailable() -> Bool {
        if let refUnicodePng = Character.refUnicodePng,
            let myPng = self.png(ofSize: Character.refUnicodeSize) {
            return refUnicodePng != myPng
        }
        return false
    }
}
