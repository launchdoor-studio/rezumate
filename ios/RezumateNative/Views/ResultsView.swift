import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var appState: AppState
    let result: AnalyzeResponse

    @State private var currentResult: AnalyzeResponse
    @State private var exportedURL: URL?
    @State private var isWorking = false
    @State private var isRefreshingAnalysis = false
    @State private var errorMessage: String?
    @State private var expandedScores: Set<String> = []
    @State private var rewriteItem: RewriteItem?

    init(result: AnalyzeResponse) {
        self.result = result
        _currentResult = State(initialValue: result)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                refinementNotice
                scoreHeader
                componentScores
                keywordSection(title: "Matched keywords", items: currentResult.matchedKeywords, color: RezTheme.success)
                keywordSection(title: "Missing keywords", items: currentResult.missingKeywords, color: RezTheme.warning)
                bulletsSection
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
            .padding(.bottom, 180)
        }
        .rezScreenBackground()
        .navigationTitle("Results")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await reAnalyze() }
                } label: {
                    if isRefreshingAnalysis {
                        ProgressView()
                            .tint(RezTheme.ink)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(RezTheme.ink)
                    }
                }
                .disabled(isRefreshingAnalysis)
                .accessibilityLabel("Re-analyze")
            }
        }
        .sheet(item: $rewriteItem) { item in
            BulletRewriteSheet(
                originalBullet: item.bullet,
                missingKeywords: currentResult.missingKeywords,
                appState: appState,
                onAccept: { newBullet in
                    accept(original: item.bullet, rewritten: newBullet)
                }
            )
        }
        .task {
            await pollForRefinedAnalysis()
        }
    }

    private var refinementNotice: some View {
        Group {
            if currentResult.analysisStatus == "pending" {
                RezCard(padding: 14) {
                    HStack(spacing: 12) {
                        ProgressView()
                            .tint(RezTheme.ink)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("AI refinement running")
                                .font(.subheadline.weight(.black))
                                .foregroundStyle(RezTheme.ink)
                            Text("Showing a fast baseline while Groq improves the score and suggestions.")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RezTheme.muted)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var scoreHeader: some View {
        RezCard(padding: 18) {
            HStack(alignment: .center, spacing: 18) {
                VStack(spacing: 2) {
                    Text("\(currentResult.score)")
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
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle("Score breakdown", subtitle: "Tap a score for details & diagnosis")
                ForEach(currentResult.componentScores.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    let isExpanded = expandedScores.contains(key)
                    VStack(alignment: .leading, spacing: 6) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if isExpanded {
                                    expandedScores.remove(key)
                                } else {
                                    expandedScores.insert(key)
                                }
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(RezTheme.ink)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Text("\(value)")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(RezTheme.ink)
                                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(RezTheme.muted)
                                    }
                                }
                                ProgressView(value: Double(value), total: 100)
                                    .tint(componentColor(value))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 2)
                                            .stroke(RezTheme.ink.opacity(0.4), lineWidth: 1)
                                    }
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if isExpanded {
                            VStack(alignment: .leading, spacing: 10) {
                                let (importance, explanation) = scoreDetails(for: key)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("WHY IT MATTERS")
                                        .font(.system(size: 8, weight: .black))
                                        .foregroundStyle(RezTheme.muted)
                                    Text(importance)
                                        .font(.caption)
                                        .foregroundStyle(RezTheme.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Divider()
                                    .background(RezTheme.ink)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("DIAGNOSIS & FEEDBACK")
                                        .font(.system(size: 8, weight: .black))
                                        .foregroundStyle(RezTheme.muted)
                                    Text(explanation)
                                        .font(.caption)
                                        .foregroundStyle(RezTheme.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(10)
                            .background(RezTheme.appBackground, in: RoundedRectangle(cornerRadius: 6))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(RezTheme.ink, lineWidth: 1.5)
                            }
                            .padding(.top, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    if key != currentResult.componentScores.sorted(by: { $0.key < $1.key }).last?.key {
                        Divider()
                            .background(RezTheme.ink.opacity(0.2))
                            .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private func scoreDetails(for key: String) -> (String, String) {
        switch key {
        case "formatting_risk":
            let importance = "Most hiring pipelines run resumes through digital parser APIs. If a file has complex layouts, multi-column tables, or unreadable characters, it won't load into recruiter databases correctly."
            let explanation: String
            if currentResult.formattingWarnings.isEmpty {
                explanation = "Excellent! Your resume layout passed all formatting parser rules and is fully optimized for digital importing."
            } else {
                explanation = "Your resume has \(currentResult.formattingWarnings.count) formatting risk(s) that might disrupt digital parsers: \(currentResult.formattingWarnings.joined(separator: ", "))."
            }
            return (importance, explanation)
            
        case "impact_quality":
            let importance = "Human recruiters spend only 6 seconds scanning a resume. Bullet points containing metrics (percentages, numbers, scale) capture their attention instantly and prove the outcome of your work, rather than just listing daily tasks."
            let bulletsWithImpact = currentResult.bulletCount - currentResult.bulletsWithoutMeasurableImpact.count
            let explanation = "Only \(bulletsWithImpact) out of \(currentResult.bulletCount) bullets contain quantifiable metrics. Add numbers, percentages, or scale units to the remaining \(currentResult.bulletsWithoutMeasurableImpact.count) bullets to improve."
            return (importance, explanation)
            
        case "keyword_coverage":
            let importance = "ATS systems rank applications based on keyword density. If your resume lacks the specific skills, languages, and tools requested in the job description, you won't surface in recruiter searches."
            let totalKeywords = currentResult.matchedKeywords.count + currentResult.missingKeywords.count
            let explanation = "Matched \(currentResult.matchedKeywords.count) out of \(totalKeywords) keywords requested by the employer (\(currentResult.keywordCoverage)% coverage). Incorporate the missing skills shown below to rank higher."
            return (importance, explanation)
            
        case "structure_readability":
            let importance = "Clear document sections ensure automatic parsers can index your experiences correctly, and help humans scan your career timeline. Missing sections like Education or Skills hurt readability."
            let missing = currentResult.sections.filter { !$0.value }.map { $0.key.capitalized }
            let explanation: String
            if missing.isEmpty {
                explanation = "Excellent. All standard resume sections (Summary, Experience, Projects, Skills, and Education) are clearly present and parseable."
            } else {
                explanation = "Missing or unparseable section(s): \(missing.joined(separator: ", ")). Check your headers so automatic parsers map your work history correctly."
            }
            return (importance, explanation)
            
        default:
            return ("", "")
        }
    }

    private var scoreColor: Color {
        componentColor(currentResult.score)
    }

    private var scoreMessage: String {
        switch currentResult.score {
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
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.82)
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

    private var improvableBullets: [String] {
        var list: [String] = []
        for bullet in currentResult.weakBullets + currentResult.bulletsWithoutMeasurableImpact {
            if !list.contains(bullet) {
                list.append(bullet)
            }
        }
        return list
    }

    private var bulletsSection: some View {
        RezCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle("Weak bullets", subtitle: "Tap one to rewrite")
                if improvableBullets.isEmpty {
                    Text("No weak bullets detected.")
                        .font(.subheadline)
                        .foregroundStyle(RezTheme.muted)
                } else {
                    ForEach(improvableBullets, id: \.self) { bullet in
                        Button {
                            rewriteItem = RewriteItem(bullet: bullet)
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

    private func accept(original: String, rewritten: String) {
        guard let token = appState.token else { return }
        isWorking = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await appState.api.acceptRewrite(
                    variantId: currentResult.variantId,
                    originalBullet: original,
                    rewrittenBullet: rewritten,
                    token: token
                )
                
                // Recalculate analysis using the updated text
                let reAnalysis = try await appState.api.analysisResult(id: response.variantId, token: token)
                
                DispatchQueue.main.async {
                    currentResult = reAnalysis
                    appState.latestAnalysis = reAnalysis
                    isWorking = false
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    isWorking = false
                }
            }
        }
    }

    private func export() async {
        guard let token = appState.token else { return }
        isWorking = true
        errorMessage = nil
        do {
            exportedURL = try await appState.api.exportVariant(id: currentResult.variantId, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
        isWorking = false
    }

    private func reAnalyze() async {
        guard let token = appState.token,
              let upload = appState.upload,
              !isRefreshingAnalysis else { return }
        
        isRefreshingAnalysis = true
        errorMessage = nil
        
        do {
            let variantDetail = try await appState.api.variant(id: currentResult.variantId, token: token)
            let currentResumeText = variantDetail.tailoredContent.rawText ?? ""
            
            let result = try await appState.api.analyzeResume(
                resumeId: upload.resumeId,
                resumeText: currentResumeText,
                jobDescription: appState.jobDescription,
                token: token
            )
            currentResult = result
            appState.latestAnalysis = result
        } catch {
            errorMessage = error.localizedDescription
        }
        isRefreshingAnalysis = false
    }

    private func pollForRefinedAnalysis() async {
        guard currentResult.analysisStatus == "pending",
              let token = appState.token,
              !isRefreshingAnalysis else {
            return
        }

        isRefreshingAnalysis = true
        defer { isRefreshingAnalysis = false }

        for _ in 0..<20 {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if Task.isCancelled { return }

            do {
                let refreshed = try await appState.api.analysisResult(id: currentResult.variantId, token: token)
                currentResult = refreshed
                appState.latestAnalysis = refreshed
                if refreshed.analysisStatus != "pending" {
                    return
                }
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }
    }
}

struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(Array(items), id: \.self) { item in
                content(item)
                    .frame(minHeight: 34)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct RewriteItem: Identifiable {
    let id = UUID()
    let bullet: String
}

struct BulletRewriteSheet: View {
    let originalBullet: String
    let missingKeywords: [String]
    let appState: AppState
    let onAccept: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var bulletText: String
    @State private var suggestions: [String] = []
    @State private var isWorking = false
    @State private var errorMessage: String?
    
    init(originalBullet: String, missingKeywords: [String], appState: AppState, onAccept: @escaping (String) -> Void) {
        self.originalBullet = originalBullet
        self.missingKeywords = missingKeywords
        self.appState = appState
        self.onAccept = onAccept
        _bulletText = State(initialValue: originalBullet)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("EDIT ORIGINAL BULLET")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(RezTheme.muted)
                        
                        TextEditor(text: $bulletText)
                            .frame(minHeight: 96)
                            .padding(10)
                            .scrollContentBackground(.hidden)
                            .rezInputSurface()
                    }
                    
                    Button {
                        Task { await generateRewrites() }
                    } label: {
                        HStack {
                            if isWorking {
                                ProgressView()
                                    .tint(RezTheme.ink)
                                    .padding(.trailing, 6)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isWorking ? "Optimizing..." : "Optimize with Llama")
                        }
                    }
                    .buttonStyle(RezPrimaryButtonStyle())
                    .disabled(bulletText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isWorking)
                    
                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RezTheme.ink)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RezTheme.error, in: RoundedRectangle(cornerRadius: 6))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(RezTheme.ink, lineWidth: 1.5)
                            }
                    }
                    
                    if !suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("SUGGESTED REWRITES (TAP TO ACCEPT)")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(RezTheme.muted)
                            
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button {
                                    onAccept(suggestion)
                                    dismiss()
                                } label: {
                                    HStack(alignment: .top, spacing: 10) {
                                        Text(suggestion)
                                            .font(.subheadline)
                                            .foregroundStyle(RezTheme.ink)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Image(systemName: "checkmark.circle")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(RezTheme.link)
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
                .padding()
            }
            .rezScreenBackground()
            .navigationTitle("Optimize Bullet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.body.weight(.bold))
                    .foregroundStyle(RezTheme.ink)
                }
            }
            .task {
                // Auto-trigger rewrite on open to make it extremely fast!
                await generateRewrites()
            }
        }
        .preferredColorScheme(.light)
    }
    
    private func generateRewrites() async {
        guard let token = appState.token else { return }
        isWorking = true
        errorMessage = nil
        do {
            let response = try await appState.api.rewriteBullet(bulletText, focusKeywords: missingKeywords, token: token)
            suggestions = response.rewrittenBullets
        } catch {
            errorMessage = error.localizedDescription
        }
        isWorking = false
    }
}
