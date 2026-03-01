import SwiftUI
import CoreData

struct CardDetailView: View {
    let card: UserCard
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameManager: GameManager
    
    @State private var showingLevelUp = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Card Visual
                    cardVisual
                    
                    // Stats Section
                    statsSection
                    
                    // Level Progress
                    levelProgressSection
                    
                    // Card Info
                    cardInfoSection
                    
                    // Actions
                    actionsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("卡片详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Card Visual
    private var cardVisual: some View {
        if let template = card.getTemplate(context: context) {
            return AnyView(
                VStack(spacing: 16) {
                    // Rarity Banner
                    HStack {
                        ForEach(0..<rarityStars(template.rarityEnum), id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                    .font(.title3)
                    
                    // Character Image
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        rarityColor(template.rarityEnum),
                                        rarityColor(template.rarityEnum).opacity(0.5)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: rarityColor(template.rarityEnum).opacity(0.5), radius: 20, x: 0, y: 10)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    
                    // Name and Series
                    VStack(spacing: 4) {
                        Text(template.characterName ?? "Unknown")
                            .font(.title.bold())
                        
                        Text(template.animeSeries ?? "Unknown")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Rarity Badge
                    Text(template.rarityEnum.rawValue)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(rarityColor(template.rarityEnum))
                        .cornerRadius(20)
                    
                    // Level Badge
                    Text("Lv. \(card.level)")
                        .font(.title2.bold())
                        .foregroundColor(.purple)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(20)
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    private func rarityStars(_ rarity: Rarity) -> Int {
        switch rarity {
        case .N: return 1
        case .R: return 2
        case .SR: return 3
        case .SSR: return 4
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: 16) {
            Text("属性")
                .font(.headline)
            
            HStack(spacing: 24) {
                // Attack
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "flame.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    
                    Text("攻击力")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(card.getCurrentAttack(context: context))")
                        .font(.title2.bold())
                        .foregroundColor(.red)
                }
                
                // Defense
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "shield.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    Text("防御力")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(card.getCurrentDefense(context: context))")
                        .font(.title2.bold())
                        .foregroundColor(.blue)
                }
                
                // Total
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "sum")
                            .font(.title2)
                            .foregroundColor(.purple)
                    }
                    
                    Text("总战力")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(card.getTotalStats(context: context))")
                        .font(.title2.bold())
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Level Progress
    private var levelProgressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("等级进度")
                    .font(.headline)
                Spacer()
                Text("Lv.\(card.level)")
                    .font(.subheadline.bold())
                    .foregroundColor(.purple)
            }
            
            // Progress Bar
            VStack(spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                            .cornerRadius(6)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.purple, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * card.experienceProgress, height: 12)
                            .cornerRadius(6)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Text("经验: \(card.experience)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("下一级: \(card.experienceNeeded)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Level Up Button (Demo)
            Button {
                addExperience()
            } label: {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                    Text("获取经验 (+50)")
                }
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.purple)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .alert("升级!", isPresented: $showingLevelUp) {
            Button("太棒了!") { }
        } message: {
            Text("卡片升级到 Lv.\(card.level)!")
        }
    }
    
    // MARK: - Card Info
    private var cardInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("卡片信息")
                .font(.headline)
            
            VStack(spacing: 8) {
                InfoDetailRow(label: "获得时间", value: card.formattedObtainDate)
                
                if card.isBoosted {
                    InfoDetailRow(label: "获取方式", value: "概率提升获得 ⭐")
                } else {
                    InfoDetailRow(label: "获取方式", value: "普通抽卡")
                }
                
                InfoDetailRow(label: "收藏状态", value: card.isFavorite ? "已收藏 ❤️" : "未收藏")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                if let cardId = card.id {
                    gameManager.toggleFavorite(cardId: cardId)
                }
            } label: {
                HStack {
                    Image(systemName: card.isFavorite ? "heart.fill" : "heart")
                    Text(card.isFavorite ? "取消收藏" : "添加收藏")
                }
                .font(.headline)
                .foregroundColor(card.isFavorite ? .white : .red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(card.isFavorite ? Color.red : Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Methods
    private func rarityColor(_ rarity: Rarity) -> Color {
        switch rarity {
        case .N: return .gray
        case .R: return .green
        case .SR: return .blue
        case .SSR: return .orange
        }
    }
    
    private func addExperience() {
        let didLevelUp = card.addExperience(50, context: context)
        if didLevelUp {
            showingLevelUp = true
        }
    }
}

// MARK: - Supporting Views

struct InfoDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
    }
}

#Preview {
    // Preview would need a mock card
    Text("Card Detail Preview")
}
