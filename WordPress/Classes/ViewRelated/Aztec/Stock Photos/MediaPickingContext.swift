/// Encapsulates context parameters to initiate a flow to pick media from several sources
struct MediaPickingContext {
    let origin: UIViewController & UIDocumentPickerDelegate
    let view: UIView
    let barButtonItem: UIBarButtonItem?
    let blog: Blog

    init(origin: UIViewController & UIDocumentPickerDelegate, view: UIView, barButtonItem: UIBarButtonItem? = nil, blog: Blog) {
        self.origin = origin
        self.view = view
        self.barButtonItem = barButtonItem
        self.blog = blog
    }
}
