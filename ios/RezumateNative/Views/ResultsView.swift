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
                keywordSection(title: "Matched keywords", items: result.matchedKeywords, color: RezTheme.success)
                keywordSection(title: "Missing keywords", items: result.missingKeywords, color: RezTheme.warning)
                bulletsSection
                rewriteSection
                exportSection

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                            .foregroundStyle(RezTheme.ink)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RezTheme.error, in: RoundedRectangle(cornerRadius: 6))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(RezTheme.ink, lineWidth: 2)
                            }
                }
            }
            .padding()
        }
        .rezScreenBackground()
        .navigationTitle("Results")
    }

    private var scoreHeader: some View {
        RezCard(padding: 18) {
            HStack(alignment: .center, spacing: 18) {
                VStack(spacing: 2) {
                    Text("\(result.score)")
                        .font(.system(size: 42, weight: .black))
                        .foregroundStyle(RezTheme.ink)
                    Text("/100")
                        .font(.caption.weight(.black))
                        .foregroundStyle(RezTheme.ink)
                }
                .frame(width: 104, height: 104)
                .background(scoreColor, in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(RezTheme.ink, lineWidth: 2)
                }
                .rezBrutalShadow(x: 3, y: 3)

                VStack(alignment: .leading, spacing: 8) {
                    Text("ATS SCORE")
                        .font(.caption.weight(.black))
                        .foregroundStyle(RezTheme.ink)
                    Text(scoreMessage)
                        .font(.subheadline)
                        .foregroundStyle(RezTheme.muted)
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
                            .overlay {
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(RezTheme.ink.opacity(0.4), lineWidth: 1)
                            }
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
        case 80...100: RezTheme.success
        case 60..<80: RezTheme.warning
        default: RezTheme.error
        }
    }

    private func keywordSection(title: String, items: [String], color: Color) -> some View {
        RezCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(title)
                if items.isEmpty {
                    Text("Nothing to show yet.")
                        .font(.subheadline)
                        .foregroundStyle(RezTheme.muted)
                } else {
                    FlowLayout(items: items) { item in
                        Text(item)
                            .font(.caption.weight(.black))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(color, in: RoundedRectangle(cornerRadius: 4))
                            .foregroundStyle(RezTheme.ink)
                            .overlay {
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(RezTheme.ink, lineWidth: 2)
                            }
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
                        .foregroundStyle(RezTheme.muted)
                } else {
                    ForEach(result.weakBullets, id: \.self) { bullet in
                        Button {
                            bulletToRewrite = bullet
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "wand.and.stars")
                                    .foregroundStyle(RezTheme.link)
                                Text(bullet)
                                    .foregroundStyle(RezTheme.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(12)
                            .background(RezTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 6))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(RezTheme.border, lineWidth: 2)
                            }
                            .rezBrutalShadow(x: 2, y: 2)
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
                    .rezInputSurface()
                Button {
                    Task { await rewrite() }
                } label: {
                    Label(isWorking ? "Rewriting..." : "Rewrite bullet", systemImage: "sparkles")
                }
                .buttonStyle(RezPrimaryButtonStyle())
                .disabled(bulletToRewrite.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isWorking)

                ForEach(rewrites, id: \.self) { rewrite in
                    Text(rewrite)
                        .font(.subheadline)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RezTheme.success, in: RoundedRectangle(cornerRadius: 6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(RezTheme.ink, lineWidth: 2)
                        }
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
                }
                .buttonStyle(RezSecondaryButtonStyle())
                .disabled(isWorking)

                if let exportedURL {
                    ShareLink(item: exportedURL) {
                        Label("Share exported PDF", systemImage: "paperplane")
                    }
                    .buttonStyle(RezPrimaryButtonStyle())
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
