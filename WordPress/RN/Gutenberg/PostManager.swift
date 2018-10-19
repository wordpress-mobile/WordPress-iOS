
import Foundation

protocol GBPostManagerDelegate: class {
    func postManagerDidSave(post: Post)
}

@objc (GBPostManager)
public class GBPostManager: NSObject, RCTBridgeModule {
    public static func moduleName() -> String! {
        return "GBPostManager"
    }

    var post: Post?
    var delegate: GBPostManagerDelegate?

    @objc(savePost:)
    func savePost(with content: String) {
        guard let post = post else {
            return
        }
        post.content = content
        PostCoordinator.shared.save(post: post)
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.postManagerDidSave(post: post)
        }
    }

    public static func requiresMainQueueSetup() -> Bool {
        return false
    }
}
