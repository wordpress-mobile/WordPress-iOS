import Foundation

class PageCoordinator {

    static func showLayoutPickerIfNeeded(forBlog blog: Blog, completion:(()->Void)) {
        if Feature.enabled(.gutenbergModalLayoutPicker) && blog.isGutenbergEnabled {
            showLayoutPicker(completion)
        } else {
            completion()
        }
    }

    private static func showLayoutPicker(_ completion:(()->Void)) {
        completion()
    }
}
