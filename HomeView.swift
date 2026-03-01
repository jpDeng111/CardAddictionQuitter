import SwiftUI
import CoreData

struct HomeView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    headerCard
                    
                    // Stats Grid
                    statsGrid
                    
                    // Screen Time Slider (Simulation)
                    screenTimeSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Today's Summary
                    todaySummarySection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("卡片戒瘾")
            .onAppear {
                gameManager.refreshStats()
            }
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日可用抽卡次数")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(gameManager.availableDraws)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.purple)
                }
                Spacer()
                
                // Probability Boost Indicator
                if gameManager.probabilityBoost > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("概率提升")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("+\(Int(gameManager.probabilityBoost * 100))%")
                            .font(.title2.bold())
                            .foregroundColor(.orange)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("屏幕时间: \(String(format: "%.1f", gameManager.simulatedScreenTime))小时")
                        .font(.caption)
                    Spacer()
                    Text("目标: 3小时内")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(progressColor)
                            .frame(width: min(geometry.size.width * (gameManager.simulatedScreenTime / 3.0), geometry.size.width), height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var progressColor: Color {
        if gameManager.simulatedScreenTime <= 1.5 {
            return .green
        } else if gameManager.simulatedScreenTime <= 3 {
            return .yellow
        } else {
            return .red
        }
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(title: "总卡片数", value: "\(gameManager.totalCards)", icon: "rectangle.stack.fill", color: .blue)
            StatCard(title: "今日已抽", value: "\(gameManager.todayDraws)", icon: "sparkles", color: .purple)
            
            let rarityCounts = gameManager.getCardsByRarity()
            StatCard(title: "SSR卡片", value: "\(rarityCounts[.SSR] ?? 0)", icon: "star.fill", color: .orange)
            StatCard(title: "SR卡片", value: "\(rarityCounts[.SR] ?? 0)", icon: "star.leadinghalf.filled", color: .cyan)
        }
    }
    
    // MARK: - Screen Time Simulation
    private var screenTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("屏幕时间模拟")
                .font(.headline)
            
            Text("(真机上会使用ScreenTime API)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("0h")
                    .font(.caption)
                Slider(value: Binding(
                    get: { gameManager.simulatedScreenTime },
                    set: { gameManager.updateSimulatedScreenTime($0) }
                ), in: 0...8, step: 0.5)
                .accentColor(.purple)
                Text("8h")
                    .font(.caption)
            }
            
            Text("当前: \(String(format: "%.1f", gameManager.simulatedScreenTime)) 小时")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速操作")
                .font(.headline)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "单抽",
                    icon: "1.circle.fill",
                    color: .purple,
                    disabled: gameManager.availableDraws < 1
                ) {
                    gameManager.performSingleDraw()
                }
                
                QuickActionButton(
                    title: "十连抽",
                    icon: "10.circle.fill",
                    color: .orange,
                    disabled: gameManager.availableDraws < 10
                ) {
                    gameManager.performTenDraw()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Today's Summary
    private var todaySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日总结")
                .font(.headline)
            
            let completedMissions = gameManager.getCompletedMissions()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("完成任务")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(completedMissions.count)")
                        .font(.title.bold())
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("概率提升")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("+\(Int(gameManager.probabilityBoost * 100))%")
                        .font(.title.bold())
                        .foregroundColor(.orange)
                }
            }
            
            if !completedMissions.isEmpty {
                Divider()
                
                ForEach(completedMissions, id: \.rawValue) { mission in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(mission.name)
                            .font(.subheadline)
                        Spacer()
                        Text("+\(Int(mission.probabilityBoost * 100))%")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.title.bold())
                Spacer()
            }
            
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let disabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                Text(title)
                    .font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(disabled ? Color.gray.opacity(0.3) : color.opacity(0.1))
            .foregroundColor(disabled ? .gray : color)
            .cornerRadius(12)
        }
        .disabled(disabled)
    }
}

#Preview {
    HomeView()
        .environmentObject(GameManager())
}
