import SwiftUI

struct BuiltPracticeLibraryView: View {
    @EnvironmentObject var appData: AppData
    
    // Filter State
    @State private var selectedFilterTag: PracticeTag? = nil // nil = All
    @State private var selectedSort: PracticeSort = .newest
    @State private var searchText: String = ""
    
    enum PracticeSort: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case mostYards = "Most yds"
        case shortest = "Shortest"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Controls
            VStack(spacing: 12) {
                // 1. Summary Line
                Text("\(filteredPractices.count) practices • \(totalYardsVisible) yds total")
                    .font(AppFont.caption.weight(.medium))
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppLayout.padding)
                
                // 2. Tag Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // "All" Chip
                        FilterChip(
                            label: "All",
                            isSelected: selectedFilterTag == nil,
                            action: { selectedFilterTag = nil }
                        )
                        
                        // Tag Chips
                        ForEach(PracticeTag.allCases) { tag in
                            FilterChip(
                                label: tag.rawValue,
                                isSelected: selectedFilterTag == tag,
                                action: { selectedFilterTag = tag }
                            )
                        }
                    }
                    .padding(.horizontal, AppLayout.padding)
                }
                
                // 3. Sort Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PracticeSort.allCases, id: \.self) { sort in
                            FilterChip(
                                label: sort.rawValue,
                                isSelected: selectedSort == sort,
                                action: { selectedSort = sort }
                            )
                        }
                    }
                    .padding(.horizontal, AppLayout.padding)
                }
                
                // 4. Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.textMuted)
                    TextField("Search by title or notes...", text: $searchText)
                        .foregroundStyle(Color.textPrimary)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.textMuted)
                        }
                    }
                }
                .padding(10)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, AppLayout.padding)
            }
            .padding(.vertical, 12)
            .background(AppColor.background)
            
            // List Content
            ScrollView {
                if filteredPractices.isEmpty {
                    emptyStateView
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredPractices) { template in
                            NavigationLink(value: BuilderDestination.detail(template)) {
                                templateRow(template)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(AppLayout.padding)
                }
            }
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("Built Practices")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Logic
    
    private var filteredPractices: [BuiltPracticeTemplate] {
        var practices = appData.builtPracticeTemplates
        
        // 1. Tag Filter
        if let tag = selectedFilterTag {
            practices = practices.filter { $0.tag == tag }
        }
        
        // 2. Search Filter
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSearch.isEmpty {
            practices = practices.filter { practice in
                practice.title.localizedCaseInsensitiveContains(trimmedSearch) ||
                (practice.notes?.localizedCaseInsensitiveContains(trimmedSearch) ?? false)
            }
        }
        
        // 3. Sort
        return practices.sorted { p1, p2 in
            switch selectedSort {
            case .newest:
                return p1.lastEditedAt > p2.lastEditedAt
            case .oldest:
                return p1.lastEditedAt < p2.lastEditedAt
            case .mostYards:
                return p1.totalYards > p2.totalYards
            case .shortest:
                return p1.totalYards < p2.totalYards
            }
        }
    }
    
    private var totalYardsVisible: String {
        let total = filteredPractices.reduce(0) { $0 + $1.totalYards }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: total)) ?? "\(total)"
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColor.accent.opacity(0.5))
            
            Text("No practices found")
                .font(AppFont.pageTitle)
                .foregroundStyle(.white)
            
            if !searchText.isEmpty || selectedFilterTag != nil {
                Text("Try adjusting your filters or search.")
                    .font(AppFont.body)
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                Text("Use Practice Builder on the Log tab to create your first template.")
                    .font(AppFont.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
        .padding(.top, 60)
    }
    
    private func templateRow(_ template: BuiltPracticeTemplate) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.title)
                            .font(AppFont.cardTitle)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        
                        // Tag Pill
                        if let tag = template.tag {
                            Text(tag.rawValue)
                                .font(AppFont.smallTag)
                                .foregroundStyle(Color.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.appAccent)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }
                
                if let notes = template.notes, !notes.isEmpty {
                    Text(notes)
                        .font(AppFont.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)
                }
                
                Divider().background(AppColor.border)
                
                HStack {
                    Text("Total: \(template.totalYards) yds")
                        .font(AppFont.caption.weight(.semibold))
                        .foregroundStyle(AppColor.accent)
                    
                    Spacer()
                    
                    Text("Edited \(template.lastEditedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(AppFont.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                // Quick Log Action
                NavigationLink(value: BuilderDestination.log(template)) {
                    Text("Log this practice")
                        .font(AppFont.caption.weight(.bold))
                        .foregroundStyle(AppColor.accent)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(AppColor.accent.opacity(0.1), in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                appData.deleteTemplate(template)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            NavigationLink(value: BuilderDestination.build(.edit(template))) {
                Label("Edit", systemImage: "pencil")
            }
        }
    }
}

// Helper View for Chips
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.caption.weight(isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.appAccent : Color.white.opacity(0.1))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}
