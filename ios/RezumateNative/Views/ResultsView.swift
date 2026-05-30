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
            VStack(alignment: .leading, spacing: 20) {
                scoreHeader
                keywordSection(title: "Matched Keywords", items: result.matchedKeywords, color: .green)
                keywordSection(title: "Missing Keywords", items: result.missingKeywords, color: .orange)
                bulletsSection
                rewriteSection
                exportSection

                if let errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .navigationTitle("Results")
    }

    private var scoreHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(result.score)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(scoreColor)
            Text("ATS match score")
                .font(.title3.weight(.semibold))
            ProgressView(value: Double(result.score), total: 100)
                .tint(scoreColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private var scoreColor: Color {
        switch result.score {
        case 80...100: .green
        case 60..<80: .orange
        default: .red
        }
    }

    private func keywordSection(title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
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

    private var bulletsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weak Bullets")
                .font(.headline)
            ForEach(result.weakBullets, id: \.self) { bullet in
                Button {
                    bulletToRewrite = bullet
                } label: {
                    Label(bullet, systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var rewriteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rewrite a Bullet")
                .font(.headline)
            TextEditor(text: $bulletToRewrite)
                .frame(minHeight: 120)
                .padding(8)
                .background(.background, in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.quaternary)
                }
            Button {
                Task { await rewrite() }
            } label: {
                Label(isWorking ? "Rewriting..." : "Rewrite", systemImage: "wand.and.stars")
            }
            .buttonStyle(.borderedProminent)
            .disabled(bulletToRewrite.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isWorking)

            ForEach(rewrites, id: \.self) { rewrite in
                Text(rewrite)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Export")
                .font(.headline)

            Button {
                Task { await export() }
            } label: {
                Label(isWorking ? "Preparing..." : "Export ATS PDF", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
            .disabled(isWorking)

            if let exportedURL {
                ShareLink(item: exportedURL) {
                    Label("Share Exported PDF", systemImage: "paperplane")
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
