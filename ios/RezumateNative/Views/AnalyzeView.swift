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
                    introHeader
                    analysisForm
                    analyzeButton

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.callout)
                            .foregroundStyle(RezTheme.error)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RezTheme.error.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(RezTheme.error.opacity(0.22))
                            }
                    }
                }
                .padding()
            }
            .rezScreenBackground()
            .navigationTitle("Analyze")
            .toolbarBackground(.visible, for: .navigationBar)
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

    private var introHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tailor for the role")
                .font(.title2.weight(.semibold))
                .foregroundStyle(RezTheme.ink)
            Text("Upload a resume, paste the job description, and review a focused ATS report.")
                .font(.subheadline)
                .foregroundStyle(RezTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
    }

    private var uploadSection: some View {
        Button {
            isShowingPicker = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: appState.upload == nil ? "doc.badge.plus" : "checkmark.circle.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(appState.upload == nil ? RezTheme.link : RezTheme.success)
                    .frame(width: 34, height: 34)
                    .background((appState.upload == nil ? RezTheme.link : RezTheme.success).opacity(0.08), in: Circle())
                    .overlay {
                        Circle()
                            .stroke((appState.upload == nil ? RezTheme.link : RezTheme.success).opacity(0.18))
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(appState.upload?.filename ?? "Attach resume")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RezTheme.ink)
                        .lineLimit(1)
                    Text(appState.upload.map { "\($0.characterCount.formatted()) characters extracted" } ?? "PDF or DOCX")
                        .font(.caption)
                        .foregroundStyle(RezTheme.muted)
                }

                Spacer()
                Text(appState.upload == nil ? "Choose" : "Change")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RezTheme.primary)
            }
        }
        .buttonStyle(.plain)
        .disabled(isUploading)
        .padding(12)
        .background(RezTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(RezTheme.border)
        }
    }

    private var analysisForm: some View {
        RezCard {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Source")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RezTheme.muted)
                        .textCase(.uppercase)
                    uploadSection

                    if isUploading {
                        ProgressView("Parsing resume...")
                            .font(.caption)
                    }

                    ForEach(appState.upload?.warnings ?? [], id: \.self) { warning in
                        Label(warning, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(RezTheme.warning)
                    }
                }

                Divider()
                    .overlay(RezTheme.border)

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Role brief")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RezTheme.ink)
                        Text("Paste the job description or recruiter notes.")
                            .font(.subheadline)
                            .foregroundStyle(RezTheme.muted)
                    }

                    TextEditor(text: $appState.jobDescription)
                        .frame(minHeight: 300)
                        .padding(12)
                        .scrollContentBackground(.hidden)
                        .background(RezTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(RezTheme.border)
                        }
                        .overlay(alignment: .topLeading) {
                            if appState.jobDescription.isEmpty {
                                Text("Paste the full role description here...")
                                    .font(.body)
                                    .foregroundStyle(RezTheme.muted.opacity(0.72))
                                    .padding(.horizontal, 17)
                                    .padding(.vertical, 20)
                                    .allowsHitTesting(false)
                            }
                        }
                }
            }
        }
    }

    private var analyzeButton: some View {
        Button {
            Task { await analyze() }
        } label: {
            Label(isAnalyzing ? "Analyzing..." : "Analyze Resume", systemImage: "sparkles")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.borderedProminent)
        .tint(RezTheme.primary)
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
