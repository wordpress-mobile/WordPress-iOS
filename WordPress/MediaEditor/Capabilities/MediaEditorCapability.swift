import Foundation

public protocol MediaEditorCapability {
    static var name: String { get }

    static var icon: UIImage { get }

    var image: UIImage { get set }

    var viewController: UIViewController { get }

    var onFinishEditing: (UIImage, [MediaEditorOperation]) -> () { get }

    var onCancel: (() -> ()) { get }

    init(_ image: UIImage,
         onFinishEditing: @escaping (UIImage, [MediaEditorOperation]) -> (),
         onCancel: @escaping () -> ())

    func apply(styles: MediaEditorStyles)
}
