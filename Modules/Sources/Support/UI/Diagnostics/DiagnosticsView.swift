import SwiftUI
import WordPressCoreProtocols

public struct DiagnosticsView: View {

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(Localization.diagnosticsDescription)
                    .foregroundStyle(.secondary)

                EmptyDiskCacheView()
            }
            .padding()
        }
        .navigationTitle(Localization.diagnosticsTitle)
        .background(.background)
        .onAppear {
            dataProvider.userDid(.viewDiagnostics)
        }
    }
}

#Preview {
    DiagnosticsView()
}
