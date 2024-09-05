import UIKit
import SwiftUI
import Combine

final class ReaderSidebarViewController: UIHostingController<ReaderSidebarView> {
    let viewModel: ReaderSidebarViewModel

    private var cancellables: [AnyCancellable] = []

    init(viewModel: ReaderSidebarViewModel) {
        self.viewModel = viewModel
        super.init(rootView: ReaderSidebarView(viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showInitialSelection() {
        cancellables = []

        viewModel.$selection.sink { [weak self] in
            self?.configure(for: $0)
        }.store(in: &cancellables)
    }

    private func configure(for selection: ReaderSidebarItem?) {
        guard let selection else {
            return
        }
        switch selection {
        case .main(let screen):
            let screenVC = makeViewController(for: screen)
            let navigationVC = UINavigationController(rootViewController: screenVC)
            splitViewController?.setViewController(navigationVC, for: .secondary)
        }
    }

    private func makeViewController(for screen: ReaderStaticScreen) -> UIViewController {
        switch screen {
        case .recent, .discover, .likes:
            if let topic = screen.topicType.flatMap(viewModel.getTopic) {
                if screen == .discover {
                    return ReaderCardsStreamViewController.controller(topic: topic)
                } else {
                    return ReaderStreamViewController.controllerWithTopic(topic)
                }
            } else {
                // TODO: (wpsidebar) add error handling (hardcode lunks to topics?)
                return UIViewController()
            }
        case .saved:
            return ReaderStreamViewController.controllerForContentType(.saved)
        case .search:
            return ReaderSearchViewController.controller(withSearchText: "")
        }
    }
}

struct ReaderSidebarView: View {
    @ObservedObject var viewModel: ReaderSidebarViewModel

    var body: some View {
        List(selection: $viewModel.selection) {
            Section {
                ForEach(ReaderStaticScreen.allCases) {
                    Label($0.localizedTitle, systemImage: $0.systemImage)
                        .tag(ReaderSidebarItem.main($0))
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(Strings.reader)
    }
}

private struct Strings {
    static let reader = NSLocalizedString("reader.sidebar.navigationTitle", value: "Reader", comment: "Reader sidebar title on iPad")
}
