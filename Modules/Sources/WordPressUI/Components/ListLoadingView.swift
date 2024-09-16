import SwiftUI

struct ListLoadingView: View {
    var body: some View {
        Color(.systemGroupedBackground).ignoresSafeArea().overlay {
            ProgressView()
        }
    }
}

#Preview {
    ListLoadingView()
}
