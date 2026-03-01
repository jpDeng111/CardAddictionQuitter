import SwiftUI
import CoreData

struct CollectionView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.managedObjectContext) private var context
    
    @State private var selectedFilter: RarityFilter = .all
    @State private var sortOption: SortOption = .dateDesc
    @State private var showFavoritesOnly = false
    @State private var selectedCard: UserCard?
    @State private var showingDetail = false
    
    enum RarityFilter: String, CaseIterable {
        case all = "全部"
        case ssr = "SSR"
        case sr = "SR"
        case r = "R"
        case n = "N"
    }
    
    enum SortOption: String, CaseIterable {
        case dateDesc = "最新获得"
        case dateAsc = "最早获得"
        case levelDesc = "等级最高"
        case rarityDesc = "稀有度"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Bar
                filterBar
                
                // Stats Summary
                statsSummary
                
                // Cards Grid
                if filteredCards.isEmpty {
                    emptyStateView
                } else {
                    cardsGrid
                }
            }
            .navigationTitle("我的收藏")
            .sheet(isPresented: $showingDetail) {
                if let card = selectedCard {
                    CardDetailView(card: card)
                }
            }
        }
    }
    
    // MARK: - Filter Bar
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Rarity Filters
                ForEach(RarityFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter,
                        color: colorForFilter(filter)
                    ) {
                        selectedFilter = filter
                    }
                }
                
                Divider()
                    .frame(height: 24)
                
                // Favorites Toggle
                FilterChip(
                    title: "收藏",
                    isSelected: showFavoritesOnly,
                    color: .red,
                    icon: "heart.fill"
                ) {
                    showFavoritesOnly.toggle()
                }
                
                // Sort Menu
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            sortOption = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOption.rawValue)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    private func colorForFilter(_ filter: RarityFilter) -> Color {
        switch filter {
        case .all: return .purple
        case .ssr: return .orange
        case .sr: return .blue
        case .r: return .green
        case .n: return .gray
        }
    }
    
    // MARK: - Stats Summary
    private var statsSummary: some View {
        let rarityCounts = gameManager.getCardsByRarity()
        
        return HStack(spacing: 16) {
            StatBadge(label: "总计", count: gameManager.totalCards, color: .purple)
            StatBadge(label: "SSR", count: rarityCounts[.SSR] ?? 0, color: .orange)
            StatBadge(label: "SR", count: rarityCounts[.SR] ?? 0, color: .blue)
            StatBadge(label: "R", count: rarityCounts[.R] ?? 0, color: .green)
            StatBadge(label: "N", count: rarityCounts[.N] ?? 0, color: .gray)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Cards Grid
    private var cardsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(filteredCards, id: \.id) { card in
                    CollectionCardView(card: card, context: context) {
                        selectedCard = card
                        showingDetail = true
                    } onFavoriteToggle: {
                        if let cardId = card.id {
                            gameManager.toggleFavorite(cardId: cardId)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "rectangle.stack.badge.minus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("还没有卡片")
                .font(.title2.bold())
                .foregroundColor(.secondary)
            
            Text("去抽卡页面获取你的第一张卡片吧！")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - Filtered Cards
    private var filteredCards: [UserCard] {
        var cards = gameManager.getUserCards()
        
        // Filter by rarity
        if selectedFilter != .all {
            cards = cards.filter { card in
                let rarity = card.getRarity(context: context)
                switch selectedFilter {
                case .ssr: return rarity == .SSR
                case .sr: return rarity == .SR
                case .r: return rarity == .R
                case .n: return rarity == .N
                case .all: return true
                }
            }
        }
        
        // Filter by favorites
        if showFavoritesOnly {
            cards = cards.filter { $0.isFavorite }
        }
        
        // Sort
        switch sortOption {
        case .dateDesc:
            cards.sort { ($0.obtainDate ?? Date()) > ($1.obtainDate ?? Date()) }
        case .dateAsc:
            cards.sort { ($0.obtainDate ?? Date()) < ($1.obtainDate ?? Date()) }
        case .levelDesc:
            cards.sort { $0.level > $1.level }
        case .rarityDesc:
            cards.sort { $0.getRarity(context: context).weight > $1.getRarity(context: context).weight }
        }
        
        return cards
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    var icon: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct StatBadge: View {
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.headline.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct CollectionCardView: View {
    let card: UserCard
    let context: NSManagedObjectContext
    let onTap: () -> Void
    let onFavoriteToggle: () -> Void
    
    var body: some View {
        if let template = card.getTemplate(context: context) {
            Button(action: onTap) {
                VStack(spacing: 8) {
                    // Header with Rarity and Favorite
                    HStack {
                        Text(template.rarityEnum.rawValue)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(rarityColor(template.rarityEnum))
                            .cornerRadius(8)
                        
                        Spacer()
                        
                        Button {
                            onFavoriteToggle()
                        } label: {
                            Image(systemName: card.isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(card.isFavorite ? .red : .gray)
                        }
                    }
                    
                    // Character
                    ZStack {
                        Circle()
                            .fill(rarityColor(template.rarityEnum).opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundColor(rarityColor(template.rarityEnum))
                    }
                    
                    // Info
                    VStack(spacing: 2) {
                        Text(template.characterName ?? "Unknown")
                            .font(.subheadline.bold())
                            .lineLimit(1)
                        
                        Text(template.animeSeries ?? "")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Level
                    HStack {
                        Text("Lv.\(card.level)")
                            .font(.caption.bold())
                            .foregroundColor(.purple)
                        
                        Spacer()
                        
                        // Stats
                        HStack(spacing: 8) {
                            Label("\(card.getCurrentAttack(context: context))", systemImage: "flame.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                            
                            Label("\(card.getCurrentDefense(context: context))", systemImage: "shield.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    func rarityColor(_ rarity: Rarity) -> Color {
        switch rarity {
        case .N: return .gray
        case .R: return .green
        case .SR: return .blue
        case .SSR: return .orange
        }
    }
}

#Preview {
    CollectionView()
        .environmentObject(GameManager())
}
