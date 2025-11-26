import SwiftUI

struct AppFont {
    // Page title: .title2.weight(.bold)
    static let pageTitle = Font.title2.weight(.bold)
    
    // Section title / card title: .headline.weight(.semibold)
    static let cardTitle = Font.headline.weight(.semibold)
    
    // Metric hero numbers: .system(size: 34–42, weight: .heavy, design: .rounded)
    static let metricHero = Font.system(size: 38, weight: .heavy, design: .rounded)
    static let metricHeroSmall = Font.system(size: 32, weight: .heavy, design: .rounded)
    
    // Subtitles: .subheadline
    static let subtitle = Font.subheadline
    
    // Supporting labels: .footnote or .caption with secondary/muted color
    static let caption = Font.caption
    static let captionMuted = Font.caption.weight(.medium)
    static let captionBold = Font.caption.weight(.bold)
    
    // Description lines: .callout or .subheadline
    static let body = Font.subheadline
    static let bodyBold = Font.subheadline.weight(.bold)
    
    // Small tags
    static let smallTag = Font.system(size: 10, weight: .bold)
    
    static let title3 = Font.title3
    
    // Legacy compatibility
    static let metricLarge = metricHeroSmall
}
