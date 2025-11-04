import SwiftUI
import WordPressCore

public struct DiagnosticsView: View {

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Run common maintenance and troubleshooting tasks.")
                    .foregroundStyle(.secondary)

                EmptyDiskCacheView()
            }
            .padding()
        }
        .navigationTitle("Diagnostics")
        .background(.background)
        .onAppear {
            dataProvider.userDid(.viewDiagnostics)
        }
    }
}

#Preview {
    DiagnosticsView()
}
