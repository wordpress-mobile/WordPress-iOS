import SwiftUI

public struct ExperimentalFeaturesList: View {

    @ObservedObject
    var viewModel: ExperimentalFeaturesViewModel

    package init(viewModel: ExperimentalFeaturesViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        List(viewModel.items) { item in
            HStack {
                Toggle(item.name, isOn: Binding<Bool>(
                    get: {
                        viewModel.dataProvider.value(for: item)
                    },
                    set: { newValue in
                        viewModel.dataProvider.didChangeValue(for: item, to: newValue)
                    }
                ))
            }
        }
        .navigationTitle(Strings.pageTitle)
        .task {
            await viewModel.loadItems()
        }
    }

    public static func asViewController(
        dataProvider: ExperimentalFeaturesViewModel.DataProvider
    ) -> UIHostingController<Self> {
        let viewModel = ExperimentalFeaturesViewModel(dataProvider: dataProvider)
        let rootView  = ExperimentalFeaturesList(viewModel: viewModel)

        let vc = UIHostingController(rootView: rootView)
        vc.title = Strings.pageTitle
        return vc
    }

    enum Strings {
        static let pageTitle = NSLocalizedString(
            "experimental-features-list.heading",
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
