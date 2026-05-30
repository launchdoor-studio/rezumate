import SwiftUI

enum RezTheme {
    static let appBackground = Color(red: 0.957, green: 0.945, blue: 0.922)
    static let surface = Color(red: 0.980, green: 0.973, blue: 0.953)
    static let elevatedSurface = Color.white
    static let ink = Color(red: 0.067, green: 0.075, blue: 0.094)
    static let muted = Color(red: 0.431, green: 0.443, blue: 0.471)
    static let border = Color(red: 0.867, green: 0.847, blue: 0.812)
    static let primary = Color(red: 0.094, green: 0.227, blue: 0.216)
    static let link = Color(red: 0.157, green: 0.345, blue: 0.651)
    static let success = Color(red: 0.157, green: 0.443, blue: 0.353)
    static let warning = Color(red: 0.718, green: 0.475, blue: 0.122)
    static let error = Color(red: 0.706, green: 0.137, blue: 0.094)
    static let line = border.opacity(0.95)

    static var displayFont: Font {
        .system(.largeTitle, design: .serif).weight(.bold)
    }
}

extension View {
    func rezScreenBackground() -> some View {
        background(RezTheme.appBackground.ignoresSafeArea())
    }

    func rezInputSurface(cornerRadius: CGFloat = 8) -> some View {
        background(RezTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(RezTheme.border)
            }
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
            .background(RezTheme.surface, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(RezTheme.border)
            }
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
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(RezTheme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(RezTheme.muted)
            }
        }
    }
}

struct RezStatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .foregroundStyle(color)
            .background(color.opacity(0.08), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(color.opacity(0.22))
            }
    }
}
