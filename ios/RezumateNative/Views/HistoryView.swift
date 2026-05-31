import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var appState: AppState
    @State private var variants: [VariantSummary] = []
    @State private var selectedVariant: VariantDetail?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if let errorMessage {
                        ErrorStateView(message: errorMessage) {
                            Task { await loadHistory() }
                        }
                    } else if variants.isEmpty && !isLoading {
                        EmptyHistoryView()
                    } else {
                        ForEach(variants) { variant in
                            Button {
                                Task { await loadVariant(variant.id) }
                            } label: {
                                HStack(spacing: 14) {
                                    VStack(spacing: 0) {
                                        Text("\(variant.atsScore ?? 0)")
                                            .font(.headline.weight(.black))
                                            .foregroundStyle(RezTheme.ink)
                                        Text("ATS")
                                            .font(.system(size: 9, weight: .black))
                                            .foregroundStyle(RezTheme.ink)
                                    }
                                    .frame(width: 48, height: 48)
                                    .background(scoreColor(variant.atsScore), in: RoundedRectangle(cornerRadius: 6))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(RezTheme.ink, lineWidth: 2)
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(variant.variantName)
                                            .font(.headline.weight(.black))
                                            .foregroundStyle(.primary)
                                        Text(variant.createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.subheadline)
                                            .foregroundStyle(RezTheme.muted)
                                    }

                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(14)
                                .background(RezTheme.surface, in: RoundedRectangle(cornerRadius: 8))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(RezTheme.border, lineWidth: 2)
                                }
                                .rezBrutalShadow()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .rezScreenBackground()
            .overlay {
                if isLoading && variants.isEmpty {
                    ProgressView("Loading history...")
                        .padding(18)
                        .background(RezTheme.surface, in: RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(RezTheme.border, lineWidth: 2)
                        }
                        .rezBrutalShadow()
                }
            }
            .navigationTitle("History")
            .toolbar {
                Button("Refresh") {
                    Task { await loadHistory() }
                }
            }
            .task {
                await loadHistory()
            }
            .navigationDestination(item: $selectedVariant) { variant in
                VariantDetailView(variant: variant)
            }
        }
    }

    private func scoreColor(_ score: Int?) -> Color {
        switch score ?? 0 {
        case 80...100: RezTheme.success
        case 60..<80: RezTheme.warning
        default: RezTheme.error
        }
    }

    private func loadHistory() async {
        guard let token = appState.token else { return }
        isLoading = true
        errorMessage = nil
        do {
            variants = try await appState.api.history(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadVariant(_ id: UUID) async {
        guard let token = appState.token else { return }
        do {
            selectedVariant = try await appState.api.variant(id: id, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension VariantDetail: Identifiable {}

private struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Could not load history", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(RezTheme.error)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(RezTheme.muted)

            Button("Try Again", action: retry)
                .buttonStyle(RezPrimaryButtonStyle())
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RezTheme.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(RezTheme.ink, lineWidth: 2)
        }
        .rezBrutalShadow()
    }
}

private struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(RezTheme.ink)
                .frame(width: 70, height: 70)
                .background(RezTheme.blueWash, in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(RezTheme.ink, lineWidth: 2)
                }

            Text("No analyses yet")
                .font(.title3.weight(.semibold))

            Text("Upload a resume and analyze it against a job description. Your results will appear here.")
                .font(.subheadline)
                .foregroundStyle(RezTheme.muted)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(RezTheme.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(RezTheme.border, lineWidth: 2)
        }
        .rezBrutalShadow()
    }
}
