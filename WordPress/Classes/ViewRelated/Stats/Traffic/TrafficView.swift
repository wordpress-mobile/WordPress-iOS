import SwiftUI

struct TrafficView: View {
    var body: some View {
        VStack {
            StatsTrafficDatePickerView()
                .padding()

            Spacer()
        }
    }
}

#Preview {
    TrafficView()
}
