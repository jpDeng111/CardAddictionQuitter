import SwiftUI
import CoreData

struct GachaView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.managedObjectContext) private var context
    @State private var showingResult = false
    @State private var animationPhase = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header Info
                    headerSection
                    
                    Spacer()
                    
                    // Main Gacha Area
                    if gameManager.isDrawing {
                        drawingAnimation
                    } else if showingResult && !gameManager.lastDrawnCards.isEmpty {
                        resultView
                    } else {
                        gachaButtons
                    }
                    
                    Spacer()
                    
                    // Probability Info
                    probabilityInfo
                }
                .padding()
            }
            .navigationTitle("抽卡")
            .sheet(isPresented: $gameManager.showDrawResult) {
                DrawResultSheet(cards: gameManager.lastDrawnCards) {
                    gameManager.showDrawResult = false
                    showingResult = true
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("可用抽卡次数")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("\(gameManager.availableDraws)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            if gameManager.probabilityBoost > 0 {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("概率UP")
                        .font(.caption.bold())
                    Text("+\(Int(gameManager.probabilityBoost * 100))%")
                        .font(.title3.bold())
                }
                .padding(12)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.8))
        .cornerRadius(16)
    }
    
    // MARK: - Drawing Animation
    private var drawingAnimation: some View {
        VStack(spacing: 20) {
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.purple.opacity(0.3), lineWidth: 3)
                        .frame(width: 150 + CGFloat(index * 50), height: 150 + CGFloat(index * 50))
                        .rotationEffect(.degrees(Double(animationPhase) * Double(index + 1) * 30))
                }
                
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                    .scaleEffect(1 + sin(Double(animationPhase) * 0.3) * 0.2)
            }
            .onAppear {
                withAnimation(.linear(duration: 0.1).repeatForever(autoreverses: false)) {
                    animationPhase += 1
                }
            }
            
            Text("抽卡中...")
                .font(.title2.bold())
                .foregroundColor(.purple)
        }
    }
    
    // MARK: - Result View
    private var resultView: some View {
        VStack(spacing: 16) {
            Text("获得了 \(gameManager.lastDrawnCards.count) 张卡片！")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(gameManager.lastDrawnCards, id: \.id) { card in
                        MiniCardView(card: card, context: context)
                    }
                }
                .padding(.horizontal)
            }
            
            Button("继续抽卡") {
                showingResult = false
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.purple)
            .cornerRadius(25)
        }
    }
    
    // MARK: - Gacha Buttons
    private var gachaButtons: some View {
        VStack(spacing: 20) {
            // Gacha Machine Visual
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 250)
                    .shadow(color: .purple.opacity(0.5), radius: 20, x: 0, y: 10)
                
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    
                    Text("抽卡")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text("点击下方按钮开始")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Draw Buttons
            HStack(spacing: 16) {
                DrawButton(
                    title: "单抽",
                    subtitle: "消耗1次",
                    cost: 1,
                    available: gameManager.availableDraws,
                    color: .purple
                ) {
                    animationPhase = 0
                    gameManager.performSingleDraw()
                }
                
                DrawButton(
                    title: "十连抽",
                    subtitle: "必得SR+",
                    cost: 10,
                    available: gameManager.availableDraws,
                    color: .orange
                ) {
                    animationPhase = 0
                    gameManager.performTenDraw()
                }
            }
        }
    }
    
    // MARK: - Probability Info
    private var probabilityInfo: some View {
        VStack(spacing: 8) {
            Text("抽卡概率")
                .font(.caption.bold())
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                ProbLabel(rarity: "SSR", prob: "1%", color: .orange)
                ProbLabel(rarity: "SR", prob: "9%", color: .blue)
                ProbLabel(rarity: "R", prob: "30%", color: .green)
                ProbLabel(rarity: "N", prob: "60%", color: .gray)
            }
            
            Text("10连抽保底SR或以上")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(16)
    }
}

// MARK: - Supporting Views

struct DrawButton: View {
    let title: String
    let subtitle: String
    let cost: Int
    let available: Int
    let color: Color
    let action: () -> Void
    
    var isDisabled: Bool {
        available < cost
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.bold())
                Text(subtitle)
                    .font(.caption)
                    .opacity(0.8)
                
                HStack(spacing: 4) {
                    Image(systemName: "sparkle")
                    Text("×\(cost)")
                }
                .font(.caption.bold())
            }
            .frame(width: 130, height: 100)
            .background(isDisabled ? Color.gray : color)
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: isDisabled ? .clear : color.opacity(0.5), radius: 10, x: 0, y: 5)
        }
        .disabled(isDisabled)
    }
}

struct ProbLabel: View {
    let rarity: String
    let prob: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(rarity)
                .font(.caption.bold())
                .foregroundColor(color)
            Text(prob)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct MiniCardView: View {
    let card: UserCard
    let context: NSManagedObjectContext
    
    var body: some View {
        if let template = card.getTemplate(context: context) {
            VStack(spacing: 8) {
                // Rarity Badge
                Text(template.rarityEnum.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(rarityColor(template.rarityEnum))
                    .cornerRadius(8)
                
                // Character Icon
                Image(systemName: "person.fill")
                    .font(.title)
                    .foregroundColor(rarityColor(template.rarityEnum))
                
                // Name
                Text(template.characterName ?? "Unknown")
                    .font(.caption.bold())
                    .lineLimit(1)
                
                Text(template.animeSeries ?? "")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 100, height: 140)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: rarityColor(template.rarityEnum).opacity(0.3), radius: 5, x: 0, y: 3)
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

// MARK: - Draw Result Sheet
struct DrawResultSheet: View {
    let cards: [UserCard]
    let onDismiss: () -> Void
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    VStack(spacing: 8) {
                        Text("恭喜获得!")
                            .font(.largeTitle.bold())
                        Text("\(cards.count) 张新卡片")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Cards Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(cards, id: \.id) { card in
                            ResultCardView(card: card, context: context)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确定") {
                        onDismiss()
                    }
                    .font(.headline)
                }
            }
        }
    }
}

struct ResultCardView: View {
    let card: UserCard
    let context: NSManagedObjectContext
    
    var body: some View {
        if let template = card.getTemplate(context: context) {
            VStack(spacing: 12) {
                // Rarity
                HStack {
                    Spacer()
                    Text(template.rarityEnum.rawValue)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(rarityColor(template.rarityEnum))
                        .cornerRadius(12)
                }
                
                // Character
                ZStack {
                    Circle()
                        .fill(rarityColor(template.rarityEnum).opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "person.fill")
                        .font(.title)
                        .foregroundColor(rarityColor(template.rarityEnum))
                }
                
                // Info
                VStack(spacing: 4) {
                    Text(template.characterName ?? "Unknown")
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(template.animeSeries ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Stats
                HStack(spacing: 16) {
                    Label("\(template.attackBonus)", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Label("\(template.defenseBonus)", systemImage: "shield.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: rarityColor(template.rarityEnum).opacity(0.3), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(rarityColor(template.rarityEnum), lineWidth: template.rarityEnum == .SSR ? 3 : 1)
            )
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
    GachaView()
        .environmentObject(GameManager())
}
