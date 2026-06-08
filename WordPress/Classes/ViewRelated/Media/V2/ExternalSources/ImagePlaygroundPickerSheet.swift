import SwiftUI
import UIKit
import WordPressMediaLibrary

#if canImport(ImagePlayground)
import ImagePlayground

@available(iOS 18.1, *)
struct ImagePlaygroundPickerSheet: View {
    let delegate: any ExternalMediaPickerDelegate
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ImagePlaygroundVCRepresentable(
            onCreated: { url in
                let stem = url.deletingPathExtension().lastPathComponent
                delegate.didPick(imagePlaygroundFile: url, suggestedName: stem)
                dismiss()
            },
            onCancelled: {
                delegate.didCancel()
                dismiss()
            }
        )
        .ignoresSafeArea()
    }
}

@available(iOS 18.1, *)
private struct ImagePlaygroundVCRepresentable: UIViewControllerRepresentable {
    let onCreated: (URL) -> Void
    let onCancelled: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = ImagePlaygroundViewController()
        // SwiftUI retains the Coordinator via context.coordinator for the lifetime
        // of the representable, so the weak `delegate` on ImagePlaygroundViewController
        // stays alive without V1's objc_setAssociatedObject workaround.
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCreated: onCreated, onCancelled: onCancelled)
    }

    @available(iOS 18.1, *)
    final class Coordinator: NSObject, ImagePlaygroundViewController.Delegate {
        let onCreated: (URL) -> Void
        let onCancelled: () -> Void

        init(onCreated: @escaping (URL) -> Void, onCancelled: @escaping () -> Void) {
            self.onCreated = onCreated
            self.onCancelled = onCancelled
        }

        func imagePlaygroundViewController(
            _ viewController: ImagePlaygroundViewController,
            didCreateImageAt url: URL
        ) {
            MainActor.assumeIsolated { onCreated(url) }
        }

        func imagePlaygroundViewControllerDidCancel(_ viewController: ImagePlaygroundViewController) {
            MainActor.assumeIsolated { onCancelled() }
        }
    }
}
#endif
