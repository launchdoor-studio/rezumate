import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var aiService = LocalAIService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    RezCard(padding: 18) {
                        HStack(spacing: 14) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundStyle(RezTheme.ink)
                                .frame(width: 54, height: 54)
                                .background(RezTheme.blueWash, in: RoundedRectangle(cornerRadius: 6))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(RezTheme.ink, lineWidth: 2)
                                }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(appState.session?.user?.email ?? "Signed in")
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(RezTheme.ink)
                                
                                Text((appState.session?.user?.planTier ?? "pro").uppercased() + " PLAN")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(RezTheme.ink)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(RezTheme.warning, in: RoundedRectangle(cornerRadius: 4))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(RezTheme.ink, lineWidth: 2)
                                    }
                            }

                            Spacer()
                        }
                    }
                    
                    RezCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle("On-Device AI Model", subtitle: "Llama 3.2 1B Instruct")
                            
                            if aiService.modelExists {
                                Label("Model loaded successfully", systemImage: "checkmark.circle.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RezTheme.success)
                                Text("Offline bullet optimization is fully enabled. Rewrites are generated directly on your Neural Engine.")
                                    .font(.caption)
                                    .foregroundStyle(RezTheme.muted)
                            } else if aiService.isDownloadingModel {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Downloading model... \(Int(aiService.downloadProgress * 100))%")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(RezTheme.ink)
                                    ProgressView(value: aiService.downloadProgress, total: 1.0)
                                        .tint(RezTheme.primary)
                                    Button("Cancel Download") {
                                        aiService.cancelDownload()
                                    }
                                    .buttonStyle(RezSecondaryButtonStyle(fill: RezTheme.error))
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Bullet optimization currently runs in rules-based fallback mode.")
                                        .font(.caption)
                                        .foregroundStyle(RezTheme.muted)
                                    Button("Download Llama 3.2 (~650MB)") {
                                        aiService.downloadModel()
                                    }
                                    .buttonStyle(RezPrimaryButtonStyle())
                                }
                            }
                        }
                    }

                    RezCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle("Account")
                            Button(role: .destructive) {
                                appState.signOut()
                            } label: {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                            .buttonStyle(RezSecondaryButtonStyle(fill: RezTheme.error))
                        }
                    }
                }
                .padding()
            }
            .rezScreenBackground()
            .navigationTitle("Profile")
        }
    }
}

