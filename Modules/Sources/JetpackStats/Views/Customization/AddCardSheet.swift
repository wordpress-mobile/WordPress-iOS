import SwiftUI

struct AddCardSheet: View {
    @ObservedObject var viewModel: StatsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCardType: CardType?
    @State private var selectedMetric: SiteMetric?
    @State private var selectedTopListItem: TopListItemType?
    
    enum CardType {
        case chart
        case topList
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if selectedCardType == nil {
                    cardTypeSelection
                } else if selectedCardType == .chart {
                    ChartCardCustomizationView(viewModel: viewModel)
                } else if selectedCardType == .topList {
                    topListItemSelection
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedCardType != nil {
                        Button(Strings.Buttons.back) {
                            handleBackAction()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Strings.Buttons.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var navigationTitle: String {
        if selectedCardType == nil {
            return Strings.AddChart.title
        } else if selectedCardType == .chart {
            return Strings.AddChart.selectMetric
        } else {
            return Strings.AddChart.selectDataType
        }
    }
    
    private var cardTypeSelection: some View {
        VStack(spacing: 0) {
            VStack(spacing: Constants.step3) {
                cardTypeButton(
                    title: Strings.AddChart.chartOption,
                    subtitle: Strings.AddChart.chartDescription,
                    icon: "chart.line.uptrend.xyaxis",
                    color: Constants.Colors.blue,
                    action: { selectedCardType = .chart }
                )
                
                cardTypeButton(
                    title: Strings.AddChart.topListOption,
                    subtitle: Strings.AddChart.topListDescription,
                    icon: "list.number",
                    color: Constants.Colors.purple,
                    action: { selectedCardType = .topList }
                )
            }
            .padding(.top, Constants.step4)
            .padding(.horizontal, Constants.step3)
            
            Spacer()
        }
    }
    
    private func cardTypeButton(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Constants.step3) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(Constants.step3)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    
    private var topListItemSelection: some View {
        ScrollView {
            VStack(spacing: Constants.step2) {
                ForEach(viewModel.context.service.supportedItems, id: \.self) { item in
                    itemButton(item: item) {
                        // For top lists, always use views as the default metric
                        viewModel.addTopList(item: item, metric: .views)
                        dismiss()
                    }
                }
            }
            .padding(Constants.step3)
        }
    }
    
    private func metricButton(metric: SiteMetric, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Constants.step2) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(metric.primaryColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: metric.systemImage)
                        .font(.body)
                        .foregroundColor(metric.primaryColor)
                }
                
                Text(metric.localizedTitle)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, Constants.step3)
            .padding(.vertical, Constants.step2)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func itemButton(item: TopListItemType, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Constants.step2) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: item.systemImage)
                        .font(.body)
                        .foregroundColor(.accentColor)
                }
                
                Text(item.localizedTitle)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, Constants.step3)
            .padding(.vertical, Constants.step2)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func handleBackAction() {
        selectedCardType = nil
    }
}
