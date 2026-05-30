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
                VStack(alignment: .leading, spacing: 14) {
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
                                    ZStack {
                                        Circle()
                                            .fill(scoreColor(variant.atsScore).opacity(0.14))
                                        Text("\(variant.atsScore ?? 0)")
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(scoreColor(variant.atsScore))
                                    }
                                    .frame(width: 54, height: 54)

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(variant.variantName)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(variant.createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(16)
                                .background(.background, in: RoundedRectangle(cornerRadius: 16))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.quaternary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemGroupedBackground))
            .overlay {
                if isLoading && variants.isEmpty {
                    ProgressView("Loading history...")
                        .padding(18)
                        .background(.background, in: RoundedRectangle(cornerRadius: 14))
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
        case 80...100: .green
        case 60..<80: .orange
        default: .red
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
                .foregroundStyle(.red)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.18))
        }
    }
}

private struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 70, height: 70)
                .background(Color.blue.opacity(0.12), in: Circle())

            Text("No analyses yet")
                .font(.title3.weight(.bold))

            Text("Upload a resume and analyze it against a job description. Your results will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}
