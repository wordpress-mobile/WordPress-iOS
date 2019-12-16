import Foundation

public protocol MediaEditorCapability {
    var image: UIImage { get set }

    var viewController: UIViewController { get }

    var onFinishEditing: (UIImage, [MediaEditorOperation]) -> () { get }

    var onCancel: (() -> ()) { get }

    init(_ image: UIImage,
         onFinishEditing: @escaping (UIImage, [MediaEditorOperation]) -> (),
         onCancel: @escaping () -> ())

    func apply(styles: MediaEditorStyles)
}
