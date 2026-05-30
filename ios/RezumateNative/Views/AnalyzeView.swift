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
                    heroHeader
                    uploadSection
                    jobDescriptionSection
                    analyzeButton

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

    private var heroHeader: some View {
        RezCard(padding: 18) {
            HStack(alignment: .center, spacing: 16) {
                Image("RezumateLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tailor for the role")
                        .font(.system(.title2, design: .serif).weight(.bold))
                        .foregroundStyle(RezTheme.ink)
                    Text("Upload a resume, paste a JD, and get targeted ATS feedback.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var uploadSection: some View {
        RezCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Resume", subtitle: "PDF or DOCX")

                Button {
                    isShowingPicker = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: appState.upload == nil ? "doc.badge.plus" : "checkmark.circle.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(appState.upload == nil ? RezTheme.blue : RezTheme.teal)
                            .frame(width: 42, height: 42)
                            .background((appState.upload == nil ? RezTheme.blue : RezTheme.teal).opacity(0.12), in: Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(appState.upload?.filename ?? "Choose resume file")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(RezTheme.ink)
                                .lineLimit(1)
                            Text(appState.upload.map { "\($0.characterCount.formatted()) characters extracted" } ?? "Securely parsed by the backend")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isUploading)

                if isUploading {
                    ProgressView("Parsing resume...")
                        .font(.caption)
                }

                ForEach(appState.upload?.warnings ?? [], id: \.self) { warning in
                    Label(warning, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(RezTheme.amber)
                }
            }
        }
    }

    private var jobDescriptionSection: some View {
        RezCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Target role", subtitle: "Paste the job description")

                TextEditor(text: $appState.jobDescription)
                    .frame(minHeight: 230)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .background(RezTheme.paper, in: RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(RezTheme.line)
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
        .tint(RezTheme.ink)
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
