import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false
    @State private var features: [WhatsNewFeature] = []
    @State private var isLoading = true
    @State private var version: String = ""
    
    init() {
        // Set default version
        _version = State(initialValue: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
        
        // Set fallback features (used if GitHub fetch fails)
        // Update these to match your current version's features
        _features = State(initialValue: [
            WhatsNewFeature(
                icon: "network",
                title: "Release Notes Unavailable",
                description: "Unable to fetch latest release notes. Please check your internet connection."
            )
        ])
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    // App Icon or Logo
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                        .scaleEffect(showContent ? 1 : 0.5)
                        .opacity(showContent ? 1 : 0)
                    
                    Text("What's New in v\(version)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : -20)
                    
                    Text("FluidVoice keeps getting better")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : -20)
                }
                .padding(.top, 40)
                .padding(.bottom, 30)
                
                // Features List
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                            FeatureRow(feature: feature)
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 30)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.8)
                                        .delay(Double(index) * 0.1),
                                    value: showContent
                                )
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                }
                
                // Continue Button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        SettingsStore.shared.markWhatsNewAsSeen()
                        dismiss()
                    }
                }) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .padding(.vertical, 30)
                .opacity(showContent ? 1 : 0)
            }
            .frame(width: 500, height: 600)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(NSColor.windowBackgroundColor).opacity(0.95))
                    .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15)
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                showContent = true
            }
            
            // Fetch release notes from GitHub
            Task {
                await fetchReleaseNotes()
            }
        }
    }
    
    // MARK: - GitHub Release Notes Fetching
    
    private func fetchReleaseNotes() async {
        do {
            let (fetchedVersion, notes) = try await SimpleUpdater.shared.fetchLatestReleaseNotes(
                owner: "altic-dev",
                repo: "Fluid-oss"
            )
            
            // Parse release notes into features
            let parsedFeatures = parseReleaseNotes(notes)
            
            await MainActor.run {
                if !parsedFeatures.isEmpty {
                    self.features = parsedFeatures
                }
                // Update version to match GitHub release
                if fetchedVersion.hasPrefix("v") {
                    self.version = String(fetchedVersion.dropFirst())
                } else {
                    self.version = fetchedVersion
                }
                self.isLoading = false
            }
        } catch {
            // If GitHub fetch fails, keep the fallback features
            print("Failed to fetch release notes: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func parseReleaseNotes(_ notes: String) -> [WhatsNewFeature] {
        var features: [WhatsNewFeature] = []
        
        // Parse markdown format:
        // - Look for bullet points (-, *, +)
        // - Look for headings (##, ###)
        // - Extract feature descriptions
        
        let lines = notes.components(separatedBy: .newlines)
        var currentTitle: String?
        var currentDescription = ""
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines
            if trimmed.isEmpty {
                continue
            }
            
            // Check for bullet points or list items
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                // Save previous feature if exists
                if let title = currentTitle, !currentDescription.isEmpty {
                    features.append(createFeature(title: title, description: currentDescription))
                }
                
                // Extract new feature
                let content = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                
                // Check if it has a colon (title: description format)
                if let colonIndex = content.firstIndex(of: ":") {
                    currentTitle = String(content[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                    currentDescription = String(content[content.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                } else {
                    // Entire content is the title/description
                    currentTitle = content
                    currentDescription = ""
                }
            }
            // Check for headings (secondary features)
            else if trimmed.hasPrefix("###") {
                if let title = currentTitle, !currentDescription.isEmpty {
                    features.append(createFeature(title: title, description: currentDescription))
                }
                currentTitle = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                currentDescription = ""
            }
            // Continuation of description
            else if currentTitle != nil && !trimmed.hasPrefix("#") {
                if !currentDescription.isEmpty {
                    currentDescription += " "
                }
                currentDescription += trimmed
            }
        }
        
        // Add last feature
        if let title = currentTitle, !currentDescription.isEmpty {
            features.append(createFeature(title: title, description: currentDescription))
        } else if let title = currentTitle {
            features.append(createFeature(title: title, description: title))
        }
        
        return features
    }
    
    private func createFeature(title: String, description: String) -> WhatsNewFeature {
        // Determine icon based on keywords in title
        let lowerTitle = title.lowercased()
        let icon: String
        
        if lowerTitle.contains("fix") || lowerTitle.contains("bug") {
            icon = "checkmark.circle"
        } else if lowerTitle.contains("performance") || lowerTitle.contains("faster") || lowerTitle.contains("speed") {
            icon = "bolt.fill"
        } else if lowerTitle.contains("new") || lowerTitle.contains("add") || lowerTitle.contains("feature") {
            icon = "sparkles"
        } else if lowerTitle.contains("audio") || lowerTitle.contains("sound") || lowerTitle.contains("microphone") {
            icon = "waveform"
        } else if lowerTitle.contains("ui") || lowerTitle.contains("design") || lowerTitle.contains("interface") {
            icon = "paintbrush.fill"
        } else if lowerTitle.contains("setting") || lowerTitle.contains("option") || lowerTitle.contains("config") {
            icon = "gearshape.2"
        } else if lowerTitle.contains("update") || lowerTitle.contains("improve") {
            icon = "arrow.up.circle"
        } else {
            icon = "star.fill"
        }
        
        return WhatsNewFeature(icon: icon, title: title, description: description.isEmpty ? title : description)
    }
}

struct FeatureRow: View {
    let feature: WhatsNewFeature
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.2),
                                Color.blue.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 6) {
                Text(feature.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(feature.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct WhatsNewFeature {
    let icon: String
    let title: String
    let description: String
}

#Preview {
    WhatsNewView()
}

