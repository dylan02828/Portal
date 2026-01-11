import SwiftUI

// MARK: - Check For Updates View
/// A modern, user-friendly view for checking and displaying app updates
struct CheckForUpdatesView: View {
    @StateObject private var updateManager = UpdateManager()
    @State private var showFullReleaseNotes = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    private let repoOwner = "aoyn1xw"
    private let repoName = "Portal"
    
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.2"
    }
    
    var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero Section
                heroSection
                
                // Update Status Card
                updateStatusCard
                
                // What's New Section (if update available)
                if updateManager.isUpdateAvailable, let release = updateManager.latestRelease {
                    whatsNewSection(release)
                }
                
                // Previous Releases
                if updateManager.allReleases.count > 1 {
                    previousReleasesSection
                }
                
                // Error Section
                if let error = updateManager.errorMessage {
                    errorSection(error)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Check For Updates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    updateManager.checkForUpdates()
                } label: {
                    if updateManager.isCheckingUpdates {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(updateManager.isCheckingUpdates)
            }
        }
        .onAppear {
            if !updateManager.hasChecked {
                updateManager.checkForUpdates()
            }
        }
        .sheet(isPresented: $showFullReleaseNotes) {
            if let release = updateManager.latestRelease {
                FullReleaseNotesView(release: release)
            }
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 20) {
            // App Icon with glow effect
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accentColor.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 10)
                
                if let iconName = Bundle.main.iconFileName,
                   let icon = UIImage(named: iconName) {
                    Image(uiImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: .accentColor.opacity(0.4), radius: 15, x: 0, y: 8)
                } else {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(LinearGradient(colors: [.accentColor, .accentColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "app.badge.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.white)
                        )
                        .shadow(color: .accentColor.opacity(0.4), radius: 15, x: 0, y: 8)
                }
            }
            .padding(.top, 20)
            
            // App Name and Version
            VStack(spacing: 8) {
                Text("Portal")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                
                // Modern version badge
                HStack(spacing: 8) {
                    Text("v\(currentVersion)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.primary)
                    
                    Text("Build \(currentBuild)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.accentColor)
                        )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(UIColor.tertiarySystemBackground))
                )
            }
            
            // Check for Updates Button
            Button {
                updateManager.checkForUpdates()
            } label: {
                HStack(spacing: 12) {
                    if updateManager.isCheckingUpdates {
                        LoadingDotsView()
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(updateManager.isCheckingUpdates ? "Checking for Updates" : "Check for Updates")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: horizontalSizeClass == .regular ? 320 : .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .foregroundStyle(.white)
                .shadow(color: .accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .disabled(updateManager.isCheckingUpdates)
            .scaleEffect(updateManager.isCheckingUpdates ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: updateManager.isCheckingUpdates)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Update Status Card
    private var updateStatusCard: some View {
        VStack(spacing: 0) {
            if updateManager.hasChecked {
                if updateManager.isUpdateAvailable, let release = updateManager.latestRelease {
                    // Update Available
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            // Animated icon
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 56, height: 56)
                                
                                if #available(iOS 17.0, *) {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(.green)
                                        .symbolEffect(.pulse, options: .repeating)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(.green)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Update Available")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("Version \(release.tagName.replacingOccurrences(of: "v", with: ""))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            // New badge
                            Text("NEW")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.green)
                                )
                        }
                        
                        // Download button
                        Button {
                            updateManager.downloadUpdate()
                        } label: {
                            HStack(spacing: 10) {
                                if updateManager.isDownloading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.down.to.line.compact")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                
                                if updateManager.isDownloading {
                                    Text("Downloading... \(Int(updateManager.downloadProgress * 100))%")
                                        .font(.system(size: 15, weight: .semibold))
                                } else {
                                    Text("Download Update")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.green)
                                    
                                    // Progress overlay
                                    if updateManager.isDownloading {
                                        GeometryReader { geo in
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color.green.opacity(0.3))
                                                .frame(width: geo.size.width * updateManager.downloadProgress)
                                        }
                                    }
                                }
                            )
                            .foregroundStyle(.white)
                        }
                        .disabled(updateManager.isDownloading)
                    }
                } else {
                    // Up to Date
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("You're Up to Date")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text("Portal \(currentVersion) is the latest version")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            } else {
                // Not checked yet
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Check for Updates")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("Tap the button above to check")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    updateManager.isUpdateAvailable ? Color.green.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - What's New Section
    private func whatsNewSection(_ release: GitHubRelease) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("What's New")
                    .font(.title3.bold())
                
                Spacer()
                
                // Modern build badge
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 10))
                    Text(release.tagName)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            
            // Release date
            if let date = release.publishedAt {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text("Released \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            // Release notes preview
            if let body = release.body, !body.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(body)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(5)
                    
                    // View More button
                    Button {
                        showFullReleaseNotes = true
                        HapticsManager.shared.softImpact()
                    } label: {
                        HStack(spacing: 6) {
                            Text("View More")
                                .font(.subheadline.weight(.medium))
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(Color.accentColor)
                    }
                }
            }
            
            // Prerelease badge if applicable
            if release.prerelease {
                HStack(spacing: 6) {
                    Image(systemName: "testtube.2")
                        .font(.caption)
                    Text("BETA RELEASE")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.15))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Previous Releases Section
    private var previousReleasesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Previous Releases")
                .font(.title3.bold())
                .padding(.horizontal, 4)
            
            previousReleasesListContent
        }
    }
    
    private var previousReleasesListContent: some View {
        let releases = Array(updateManager.allReleases.dropFirst().prefix(5))
        
        return VStack(spacing: 0) {
            ForEach(Array(releases.enumerated()), id: \.element.id) { index, release in
                previousReleaseRow(release: release, index: index, totalCount: releases.count)
            }
            
            viewAllReleasesButton
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    private func previousReleaseRow(release: GitHubRelease, index: Int, totalCount: Int) -> some View {
        VStack(spacing: 0) {
            Button {
                if let url = URL(string: release.htmlUrl) {
                    UIApplication.shared.open(url)
                }
                HapticsManager.shared.softImpact()
            } label: {
                releaseRowContent(release: release)
            }
            
            if index < totalCount - 1 {
                Divider()
                    .padding(.leading, 16)
            }
        }
    }
    
    private func releaseRowContent(release: GitHubRelease) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(release.tagName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    if release.prerelease {
                        betaBadge
                    }
                }
                
                if let date = release.publishedAt {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
    
    private var betaBadge: some View {
        Text("BETA")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.15))
            )
    }
    
    @ViewBuilder
    private var viewAllReleasesButton: some View {
        if updateManager.allReleases.count > 6 {
            Divider()
                .padding(.leading, 16)
            
            Button {
                if let url = URL(string: "https://github.com/\(repoOwner)/\(repoName)/releases") {
                    UIApplication.shared.open(url)
                }
                HapticsManager.shared.softImpact()
            } label: {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundStyle(Color.accentColor)
                    Text("View All Releases")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Error Section
    private func errorSection(_ error: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Unable to Check for Updates")
                    .font(.subheadline.weight(.semibold))
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

// MARK: - Loading Dots Animation View
struct LoadingDotsView: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animationPhase == index ? 1.3 : 0.8)
                    .opacity(animationPhase == index ? 1 : 0.5)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: false)) {
                animationPhase = 2
            }
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

// MARK: - Full Release Notes View
struct FullReleaseNotesView: View {
    let release: GitHubRelease
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            // Version badge
                            HStack(spacing: 6) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 12))
                                Text(release.tagName)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.purple, Color.blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            
                            if release.prerelease {
                                Text("BETA")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.orange.opacity(0.15))
                                    )
                            }
                        }
                        
                        Text(release.name)
                            .font(.title2.bold())
                        
                        if let date = release.publishedAt {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                Text("Released \(date.formatted(date: .long, time: .omitted))")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Release notes content
                    if let body = release.body, !body.isEmpty {
                        Text(body)
                            .font(.body)
                            .foregroundStyle(.primary)
                    } else {
                        Text("No release notes available.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                    
                    // Assets section
                    if !release.assets.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Downloads")
                                .font(.headline)
                            
                            ForEach(release.assets) { asset in
                                HStack {
                                    Image(systemName: "doc.zipper")
                                        .foregroundStyle(Color.accentColor)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(asset.name)
                                            .font(.subheadline.weight(.medium))
                                        Text(formatFileSize(asset.size))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        if let url = URL(string: asset.browserDownloadUrl) {
                                            UIApplication.shared.open(url)
                                        }
                                    } label: {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color(UIColor.tertiarySystemBackground))
                                )
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Release Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Update Manager
class UpdateManager: ObservableObject {
    @Published var isCheckingUpdates = false
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var latestRelease: GitHubRelease?
    @Published var allReleases: [GitHubRelease] = []
    @Published var errorMessage: String?
    @Published var hasChecked = false
    @Published var isUpdateAvailable = false
    
    private let repoOwner = "aoyn1xw"
    private let repoName = "Portal"
    private var downloadTask: URLSessionDownloadTask?
    
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.2"
    }
    
    func checkForUpdates() {
        isCheckingUpdates = true
        errorMessage = nil
        HapticsManager.shared.softImpact()
        
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isCheckingUpdates = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isCheckingUpdates = false
                self.hasChecked = true
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    HapticsManager.shared.error()
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received"
                    HapticsManager.shared.error()
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    let releases = try decoder.decode([GitHubRelease].self, from: data)
                    self.allReleases = releases.filter { !$0.prerelease }
                    self.latestRelease = self.allReleases.first
                    
                    // Check if update is available
                    if let release = self.latestRelease {
                        let releaseVersion = release.tagName.replacingOccurrences(of: "v", with: "")
                        self.isUpdateAvailable = self.compareVersions(releaseVersion, self.currentVersion) == .orderedDescending
                    }
                    
                    if self.isUpdateAvailable {
                        HapticsManager.shared.success()
                    } else {
                        HapticsManager.shared.softImpact()
                    }
                } catch {
                    self.errorMessage = "Failed to parse releases"
                    HapticsManager.shared.error()
                }
            }
        }.resume()
    }
    
    func downloadUpdate() {
        guard let release = latestRelease else { return }
        
        // Find IPA asset
        let ipaAsset = release.assets.first { $0.name.hasSuffix(".ipa") }
        
        if let asset = ipaAsset {
            downloadAsset(asset)
        } else {
            // Fallback to opening GitHub page
            if let url = URL(string: release.htmlUrl) {
                UIApplication.shared.open(url)
            }
        }
        
        HapticsManager.shared.success()
    }
    
    private func downloadAsset(_ asset: GitHubAsset) {
        guard let url = URL(string: asset.browserDownloadUrl) else { return }
        
        isDownloading = true
        downloadProgress = 0.0
        
        let session = URLSession(configuration: .default, delegate: DownloadDelegate(manager: self), delegateQueue: nil)
        downloadTask = session.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    func updateDownloadProgress(_ progress: Double) {
        DispatchQueue.main.async {
            self.downloadProgress = progress
        }
    }
    
    func downloadCompleted(at location: URL) {
        DispatchQueue.main.async {
            self.isDownloading = false
            self.downloadProgress = 1.0
            HapticsManager.shared.success()
            
            // Move file to documents
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsPath.appendingPathComponent("Portal-Update.ipa")
            
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.moveItem(at: location, to: destinationURL)
                
                // Open share sheet or handle IPA
                AppLogManager.shared.success("Update downloaded to: \(destinationURL.path)", category: "Updates")
            } catch {
                AppLogManager.shared.error("Failed to save update: \(error.localizedDescription)", category: "Updates")
            }
        }
    }
    
    func downloadFailed(with error: Error) {
        DispatchQueue.main.async {
            self.isDownloading = false
            self.errorMessage = "Download failed: \(error.localizedDescription)"
            HapticsManager.shared.error()
        }
    }
    
    private func compareVersions(_ v1: String, _ v2: String) -> ComparisonResult {
        let components1 = v1.split(separator: ".").compactMap { Int($0) }
        let components2 = v2.split(separator: ".").compactMap { Int($0) }
        
        let maxLength = max(components1.count, components2.count)
        
        for i in 0..<maxLength {
            let num1 = i < components1.count ? components1[i] : 0
            let num2 = i < components2.count ? components2[i] : 0
            
            if num1 < num2 {
                return .orderedAscending
            } else if num1 > num2 {
                return .orderedDescending
            }
        }
        
        return .orderedSame
    }
}

// MARK: - Download Delegate
class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    weak var manager: UpdateManager?
    
    init(manager: UpdateManager) {
        self.manager = manager
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        manager?.downloadCompleted(at: location)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        manager?.updateDownloadProgress(progress)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            manager?.downloadFailed(with: error)
        }
    }
}

// MARK: - Preview
#if DEBUG
struct CheckForUpdatesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CheckForUpdatesView()
        }
    }
}
#endif
