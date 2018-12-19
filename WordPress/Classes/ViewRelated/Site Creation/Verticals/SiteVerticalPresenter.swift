import Gridicons

/// Abstracts cells for SiteVerticals
protocol SiteVerticalPresenter: ReusableCell {
    var vertical: SiteVertical? { get set }
}
