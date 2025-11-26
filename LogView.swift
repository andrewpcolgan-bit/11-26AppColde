import SwiftUI
import PhotosUI

struct LogView: View {
    @EnvironmentObject var appData: AppData
    
    // Navigation
    @State private var path = NavigationPath()
    
    // Sheet States
    @State private var showCamera = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var showAnalyzeSheet = false
    @State private var selectedImageForAnalysis: IdentifiableImage? = nil
    @State private var isAnalyzing = false
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Card 1: Weekly Summary
                        weeklySummaryCard
                        
                        // Card 2: Log New Practice
                        logNewPracticeCard
                        
                        // Card 3: Practice Builder
                        practiceBuilderCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: AnalyzedPractice.self) { practice in
                PracticeDetailScreen(practice: practice)
            }
            .navigationDestination(for: BuilderDestination.self) { dest in
                switch dest {
                case .library:
                    BuiltPracticeLibraryView()
                case .build(let mode):
                    BuildPracticeView(mode: mode)
                case .log(let template):
                    LogBuiltPracticeView(template: template)
                case .detail(let template):
                    BuiltPracticeDetailView(template: template)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView { image in
                    selectedImageForAnalysis = IdentifiableImage(image: image)
                    showAnalyzeSheet = true
                }
            }
            .sheet(item: $selectedImageForAnalysis) { wrapper in
                AnalyzeView(image: wrapper.image)
                    .onAppear { isAnalyzing = true }
                    .onDisappear { isAnalyzing = false }
            }
            .onChange(of: selectedPhoto) { newItem in
                print("📸 Photo selected: \(String(describing: newItem))")
                Task {
                    guard let item = newItem else { return }
                    
                    do {
                        if let data = try await item.loadTransferable(type: Data.self) {
                            print("✅ Data loaded, size: \(data.count) bytes")
                            if let image = UIImage(data: data) {
                                print("✅ UIImage created successfully")
                                await MainActor.run {
                                    selectedImageForAnalysis = IdentifiableImage(image: image)
                                    // Reset picker selection so we can pick the same photo again if needed
                                    selectedPhoto = nil
                                }
                            } else {
                                print("❌ Failed to create UIImage from data")
                            }
                        } else {
                            print("❌ loadTransferable returned nil data")
                        }
                    } catch {
                        print("❌ Error loading photo: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Card 1: Weekly Summary
    private var weeklySummaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header Row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Log")
                            .font(AppFont.pageTitle)
                            .foregroundStyle(Color.textPrimary)
                        Text("Scan a practice sheet or add one manually.")
                            .font(AppFont.subtitle)
                            .foregroundStyle(Color.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Optional "Meet Week" pill
                    if let label = appData.currentWeekLabel, !label.isEmpty {
                        Text(label)
                            .font(AppFont.smallTag)
                            .foregroundStyle(Color.appAccent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.appAccent.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                
                // Primary Stats Row
                HStack(spacing: 0) {
                    // Total Yards
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(appData.weekTotalYards)")
                            .font(AppFont.metricHero)
                            .foregroundStyle(Color.textPrimary)
                        Text("yds this week")
                            .font(AppFont.caption)
                            .foregroundStyle(Color.textMuted)
                    }
                    
                    Spacer()
                    
                    // Sessions
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(appData.weekSessionCount)")
                            .font(AppFont.metricHero)
                            .foregroundStyle(Color.textPrimary)
                        Text("sessions")
                            .font(AppFont.caption)
                            .foregroundStyle(Color.textMuted)
                    }
                }
                
                // Divider
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Secondary Stats Row
                HStack(spacing: 12) {
                    MetricTile(
                        label: "Average Distance",
                        value: "\(appData.weekAverageDistance) yds"
                    )
                    
                    MetricTile(
                        label: "Total Time",
                        value: appData.weekTotalDuration
                    )
                }
            }
        }
    }
    
    // MARK: - Card 2: Log New Practice
    private var logNewPracticeCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.appAccent)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Log New Practice")
                            .font(AppFont.cardTitle)
                            .foregroundStyle(Color.textPrimary)
                        Text("Snap or upload a set to analyze instantly.")
                            .font(AppFont.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                
                // Loading indicator if analyzing
                if isAnalyzing {
                    HStack {
                        ProgressView()
                            .tint(Color.appAccent)
                        Text("Analyzing...")
                            .font(AppFont.body)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // Primary Action Row: Camera + Upload
                HStack(spacing: 12) {
                    // Use Camera (Primary)
                    Button {
                        showCamera = true
                    } label: {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Use Camera")
                        }
                        .font(AppFont.body.weight(.semibold))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(isAnalyzing)
                    .opacity(isAnalyzing ? 0.6 : 1)
                    
                    // Upload Photo (Secondary)
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            Image(systemName: "photo.fill")
                            Text("Upload")
                        }
                        .font(AppFont.body.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .disabled(isAnalyzing)
                    .opacity(isAnalyzing ? 0.6 : 1)
                }
                
                // Secondary Action: Log Built Practice
                NavigationLink(value: BuilderDestination.library) {
                    HStack {
                        Image(systemName: "books.vertical.fill")
                            .foregroundStyle(Color.appAccent)
                        
                        Text("Log Built Practice")
                            .font(AppFont.body.weight(.medium))
                            .foregroundStyle(Color.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.textMuted)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }
    
    // MARK: - Card 3: Practice Builder
    private var practiceBuilderCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "hammer.fill")
                        .font(.title3)
                        .foregroundStyle(Color.appAccent)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Practice Builder")
                            .font(AppFont.cardTitle)
                            .foregroundStyle(Color.textPrimary)
                        Text("Create reusable practices or grab a saved one when you need it.")
                            .font(AppFont.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                
                // Buttons Row
                HStack(spacing: 12) {
                    // Build New (Primary)
                    NavigationLink(value: BuilderDestination.build(.create)) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Build New")
                        }
                        .font(AppFont.body.weight(.semibold))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    // Library (Secondary)
                    NavigationLink(value: BuilderDestination.library) {
                        HStack {
                            Image(systemName: "books.vertical")
                            Text("Library")
                        }
                        .font(AppFont.body.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
}
