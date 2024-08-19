import SwiftUI

public struct ExperimentalFeaturesList: View {

    @ObservedObject
    var viewModel: ExperimentalFeaturesViewModel

    public init(dataProvider: ExperimentalFeaturesViewModel.DataProvider) {
        self.viewModel = ExperimentalFeaturesViewModel(dataProvider: dataProvider)
    }

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
        .navigationTitle("Experimental Features")
        .task {
            await viewModel.loadItems()
        }
    }
}

#Preview {
    NavigationView {
        ExperimentalFeaturesList(viewModel: .withSampleData())
    }
}
