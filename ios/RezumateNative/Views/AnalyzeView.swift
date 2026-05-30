import SwiftUI

struct AnalyzeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isShowingPicker = false
    @State private var isUploading = false
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var resultForSheet: AnalyzeResponse?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    uploadSection
                    jobDescriptionSection
                    analyzeButton

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Analyze")
            .sheet(isPresented: $isShowingPicker) {
                DocumentPicker { url in
                    isShowingPicker = false
                    Task { await upload(url: url) }
                }
            }
            .navigationDestination(item: $resultForSheet) { result in
                ResultsView(result: result)
            }
        }
    }

    private var uploadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resume")
                .font(.headline)

            Button {
                isShowingPicker = true
            } label: {
                HStack {
                    Image(systemName: appState.upload == nil ? "doc.badge.plus" : "checkmark.circle.fill")
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appState.upload?.filename ?? "Choose PDF or DOCX")
                            .font(.body.weight(.semibold))
                        Text(appState.upload.map { "\($0.characterCount.formatted()) characters extracted" } ?? "Your file is parsed by the backend")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(isUploading)

            if isUploading {
                ProgressView("Uploading...")
            }

            ForEach(appState.upload?.warnings ?? [], id: \.self) { warning in
                Label(warning, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var jobDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Target role")
                .font(.headline)

            TextEditor(text: $appState.jobDescription)
                .frame(minHeight: 220)
                .padding(8)
                .background(.background, in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.quaternary)
                }
        }
    }

    private var analyzeButton: some View {
        Button {
            Task { await analyze() }
        } label: {
            Label(isAnalyzing ? "Analyzing..." : "Analyze Resume", systemImage: "sparkles")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(appState.upload == nil || appState.jobDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAnalyzing)
    }

    private func upload(url: URL) async {
        guard let token = appState.token else { return }
        isUploading = true
        errorMessage = nil
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing { url.stopAccessingSecurityScopedResource() }
        }

        do {
            appState.upload = try await appState.api.uploadResume(fileURL: url, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
        isUploading = false
    }

    private func analyze() async {
        guard let token = appState.token, let upload = appState.upload else { return }
        isAnalyzing = true
        errorMessage = nil
        do {
            let result = try await appState.api.analyzeResume(
                resumeId: upload.resumeId,
                resumeText: upload.extractedText,
                jobDescription: appState.jobDescription,
                token: token
            )
            appState.latestAnalysis = result
            resultForSheet = result
        } catch {
            errorMessage = error.localizedDescription
        }
        isAnalyzing = false
    }
}

extension AnalyzeResponse: Identifiable {
    var id: UUID { variantId }
}
