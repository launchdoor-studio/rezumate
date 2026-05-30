import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var appState: AppState
    let result: AnalyzeResponse

    @State private var bulletToRewrite = ""
    @State private var rewrites: [String] = []
    @State private var exportedURL: URL?
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                scoreHeader
                componentScores
                keywordSection(title: "Matched keywords", items: result.matchedKeywords, color: RezTheme.teal)
                keywordSection(title: "Missing keywords", items: result.missingKeywords, color: RezTheme.amber)
                bulletsSection
                rewriteSection
                exportSection

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.red)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
        }
        .background(RezTheme.paper.ignoresSafeArea())
        .navigationTitle("Results")
    }

    private var scoreHeader: some View {
        RezCard(padding: 18) {
            HStack(alignment: .center, spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(scoreColor.opacity(0.14), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: CGFloat(result.score) / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(result.score)")
                        .font(.system(size: 46, weight: .bold, design: .serif))
                        .foregroundStyle(scoreColor)
                }
                .frame(width: 118, height: 118)

                VStack(alignment: .leading, spacing: 8) {
                    Text("ATS match")
                        .font(.system(.title2, design: .serif).weight(.bold))
                    Text(scoreMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var componentScores: some View {
        RezCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Score breakdown")
                ForEach(result.componentScores.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption.weight(.semibold))
                            Spacer()
                            Text("\(value)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(RezTheme.ink)
                        }
                        ProgressView(value: Double(value), total: 100)
                            .tint(componentColor(value))
                    }
                }
            }
        }
    }

    private var scoreColor: Color {
        componentColor(result.score)
    }

    private var scoreMessage: String {
        switch result.score {
        case 80...100: "Strong fit. Polish missing details and export."
        case 60..<80: "Good base. Close keyword and impact gaps."
        default: "Needs tailoring before sending."
        }
    }

    private func componentColor(_ value: Int) -> Color {
        switch value {
        case 80...100: RezTheme.teal
        case 60..<80: RezTheme.amber
        default: .red
        }
    }

    private func keywordSection(title: String, items: [String], color: Color) -> some View {
        RezCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(title)
                if items.isEmpty {
                    Text("Nothing to show yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    FlowLayout(items: items) { item in
                        Text(item)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(color.opacity(0.12), in: Capsule())
                            .foregroundStyle(color)
                    }
                }
            }
        }
    }

    private var bulletsSection: some View {
        RezCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle("Weak bullets", subtitle: "Tap one to rewrite")
                if result.weakBullets.isEmpty {
                    Text("No weak bullets detected.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(result.weakBullets, id: \.self) { bullet in
                        Button {
                            bulletToRewrite = bullet
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "wand.and.stars")
                                    .foregroundStyle(RezTheme.plum)
                                Text(bullet)
                                    .foregroundStyle(RezTheme.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(12)
                            .background(RezTheme.plum.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var rewriteSection: some View {
        RezCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle("Rewrite a bullet")
                TextEditor(text: $bulletToRewrite)
                    .frame(minHeight: 110)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .background(RezTheme.paper, in: RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(RezTheme.line)
                    }
                Button {
                    Task { await rewrite() }
                } label: {
                    Label(isWorking ? "Rewriting..." : "Rewrite bullet", systemImage: "sparkles")
                        .frame(maxWidth: .infinity, minHeight: 46)
                }
                .buttonStyle(.borderedProminent)
                .tint(RezTheme.plum)
                .disabled(bulletToRewrite.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isWorking)

                ForEach(rewrites, id: \.self) { rewrite in
                    Text(rewrite)
                        .font(.subheadline)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RezTheme.teal.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private var exportSection: some View {
        RezCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle("Export", subtitle: "Create an ATS-safe PDF")

                Button {
                    Task { await export() }
                } label: {
                    Label(isWorking ? "Preparing..." : "Export ATS PDF", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity, minHeight: 46)
                }
                .buttonStyle(.bordered)
                .disabled(isWorking)

                if let exportedURL {
                    ShareLink(item: exportedURL) {
                        Label("Share exported PDF", systemImage: "paperplane")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(RezTheme.teal)
                }
            }
        }
    }

    private func rewrite() async {
        guard let token = appState.token else { return }
        isWorking = true
        errorMessage = nil
        do {
            let response = try await appState.api.rewriteBullet(bulletToRewrite, focusKeywords: result.missingKeywords, token: token)
            rewrites = response.rewrittenBullets
        } catch {
            errorMessage = error.localizedDescription
        }
        isWorking = false
    }

    private func export() async {
        guard let token = appState.token else { return }
        isWorking = true
        errorMessage = nil
        do {
            exportedURL = try await appState.api.exportVariant(id: result.variantId, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
        isWorking = false
    }
}

struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(Array(items), id: \.self) { item in
                content(item)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
