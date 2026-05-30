import SwiftUI

enum RezTheme {
    static let ink = Color(red: 0.07, green: 0.09, blue: 0.14)
    static let blue = Color(red: 0.13, green: 0.39, blue: 0.92)
    static let teal = Color(red: 0.04, green: 0.48, blue: 0.44)
    static let amber = Color(red: 0.86, green: 0.52, blue: 0.12)
    static let plum = Color(red: 0.34, green: 0.18, blue: 0.49)
    static let paper = Color(red: 0.96, green: 0.97, blue: 0.99)
    static let line = Color.black.opacity(0.08)

    static var displayFont: Font {
        .system(.largeTitle, design: .serif).weight(.bold)
    }
}

struct RezCard<Content: View>: View {
    let padding: CGFloat
    @ViewBuilder let content: Content

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(.background, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(RezTheme.line)
            }
            .shadow(color: .black.opacity(0.04), radius: 10, y: 6)
    }
}

struct SectionTitle: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(RezTheme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
