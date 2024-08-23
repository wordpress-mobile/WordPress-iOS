import SwiftUI

public struct ExperimentalFeaturesList: View {

    @ObservedObject
    var viewModel: ExperimentalFeaturesViewModel

    package init(viewModel: ExperimentalFeaturesViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        List(viewModel.items) { item in
            Toggle(item.name, isOn: viewModel.binding(for: item))
        }
        .navigationTitle(Strings.pageTitle)
        .task {
            await viewModel.loadItems()
        }
    }

    public static func asViewController(
        viewModel: ExperimentalFeaturesViewModel
    ) -> UIHostingController<Self> {
        let rootView  = ExperimentalFeaturesList(viewModel: viewModel)

        let vc = UIHostingController(rootView: rootView)
        vc.title = Strings.pageTitle
        return vc
    }

    enum Strings {
        static let pageTitle = NSLocalizedString(
            "experimentalFeaturesList.heading",
            value: "Experimental Features",
            comment: "The title for the experimental features list"
        )
    }
}

#Preview {
    NavigationView {
        ExperimentalFeaturesList(viewModel: .withSampleData())
    }
}
