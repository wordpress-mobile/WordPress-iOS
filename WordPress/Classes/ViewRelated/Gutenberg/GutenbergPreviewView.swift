import UIKit
import Gutenberg
import Aztec

class GutenbergPreviewView: UIView {

//    required init?(coder: NSCoder) {
//        super.init
//    }
}

extension GutenbergPreviewView: GutenbergBridgeDataSource {
    func gutenbergInitialContent() -> String? {
        return nil
    }

    func gutenbergInitialTitle() -> String? {
        return nil
    }

    func aztecAttachmentDelegate() -> TextViewAttachmentDelegate {
        return self
    }

    func gutenbergLocale() -> String? {
        return nil
    }

    func gutenbergTranslations() -> [String: [String]]? {
        return nil
    }

    func gutenbergEditorTheme() -> GutenbergEditorTheme? {
        return nil
    }

    var isPreview: Bool {
        return true
    }

    var previewTemplate: String? {
        return "<!-- wp:paragraph --><p>Preview</p><!-- /wp:paragraph -->"
    }
}

extension GutenbergPreviewView: TextViewAttachmentDelegate {
    func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL? {
        return nil
    }

    func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage {
        return UIImage()
    }

    func textView(_ textView: TextView, attachment: NSTextAttachment, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) { }
    func textView(_ textView: TextView, deletedAttachment attachment: MediaAttachment) { }
    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) { }
    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) { }
}
