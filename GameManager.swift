import SwiftUI
import CoreData
import Combine

// Game Manager - Central ViewModel for managing game state
class GameManager: ObservableObject {
    // Current user ID (for demo, we use a fixed UUID)
    @Published var userId: UUID
    
    // Draw state
    @Published var availableDraws: Int = 5
    @Published var lastDrawnCards: [UserCard] = []
    @Published var isDrawing: Bool = false
    @Published var showDrawResult: Bool = false
    
    // Stats
    @Published var totalCards: Int = 0
    @Published var todayDraws: Int = 0
    @Published var probabilityBoost: Double = 0
    
    // Screen time simulation (since ScreenTime API needs real device)
    @Published var simulatedScreenTime: Double = 2.0 // hours
    
    private var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }
    
    init() {
        // Load or create user ID
        if let savedUserId = UserDefaults.standard.string(forKey: "userId"),
           let uuid = UUID(uuidString: savedUserId) {
            self.userId = uuid
        } else {
            let newUserId = UUID()
            UserDefaults.standard.set(newUserId.uuidString, forKey: "userId")
            self.userId = newUserId
        }
        
        refreshStats()
    }
    
    // MARK: - Stats
    
    func refreshStats() {
        totalCards = UserCard.countUserCards(userId: userId, context: context)
        todayDraws = getTodayDrawCount()
        probabilityBoost = DefaultMissionSystem.shared.getProbabilityBoost()
        availableDraws = calculateAvailableDraws()
    }
    
    private func getTodayDrawCount() -> Int {
        let request: NSFetchRequest<DrawRecord> = DrawRecord.fetchRequest()
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "timestamp >= %@ AND timestamp < %@", today as CVarArg, tomorrow as CVarArg),
            NSPredicate(format: "userId == %@", userId as CVarArg)
        ])
        
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
    
    private func calculateAvailableDraws() -> Int {
        // Base draws based on screen time
        let baseDraws = 5
        let penalty = max(0, Int(simulatedScreenTime) - 3)
        var draws = baseDraws - penalty
        
        // Bonus for low usage
        if simulatedScreenTime <= 1.5 {
            draws += 2
        }
        
        // Subtract today's draws
        draws -= todayDraws
        
        return max(0, min(draws, 10))
    }
    
    // MARK: - Drawing Cards
    
    func performSingleDraw() {
        guard availableDraws >= 1 else { return }
        
        isDrawing = true
        lastDrawnCards = []
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            if let card = GachaSystemV2.shared.draw(userId: self.userId, context: self.context) {
                self.lastDrawnCards = [card]
            }
            
            self.isDrawing = false
            self.showDrawResult = true
            self.refreshStats()
        }
    }
    
    func performTenDraw() {
        guard availableDraws >= 10 else { return }
        
        isDrawing = true
        lastDrawnCards = []
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            self.lastDrawnCards = GachaSystemV2.shared.drawMultiple(
                userId: self.userId,
                count: 10,
                context: self.context
            )
            
            self.isDrawing = false
            self.showDrawResult = true
            self.refreshStats()
        }
    }
    
    // MARK: - Missions
    
    func completeMission(_ missionType: MissionType) -> Bool {
        let success = DefaultMissionSystem.shared.completeMission(type: missionType)
        if success {
            refreshStats()
        }
        return success
    }
    
    func canCompleteMission(_ missionType: MissionType) -> Bool {
        return DefaultMissionSystem.shared.canCompleteMission(type: missionType)
    }
    
    func getAvailableMissions() -> [MissionType] {
        return DefaultMissionSystem.shared.getAvailableMissions()
    }
    
    func getCompletedMissions() -> [MissionType] {
        return DefaultMissionSystem.shared.getTodayCompletedMissions()
    }
    
    // MARK: - Cards Management
    
    func getUserCards() -> [UserCard] {
        let request: NSFetchRequest<UserCard> = UserCard.fetchRequest()
        request.predicate = UserCard.predicateForUser(userId: userId)
        request.sortDescriptors = UserCard.sortByObtainDateDescending
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching user cards: \(error)")
            return []
        }
    }
    
    func toggleFavorite(cardId: UUID) {
        _ = UserCard.toggleFavorite(cardId: cardId, context: context)
    }
    
    func getCardsByRarity() -> [Rarity: Int] {
        return UserCard.countByRarity(userId: userId, context: context)
    }
    
    // MARK: - Screen Time Simulation
    
    func updateSimulatedScreenTime(_ hours: Double) {
        simulatedScreenTime = hours
        refreshStats()
    }
}

// MARK: - Card Display Helper
struct CardDisplayInfo: Identifiable {
    let id: UUID
    let characterName: String
    let animeSeries: String
    let rarity: Rarity
    let level: Int16
    let isFavorite: Bool
    let obtainDate: Date
    let attack: Int
    let defense: Int
    
    static func from(userCard: UserCard, context: NSManagedObjectContext) -> CardDisplayInfo? {
        guard let template = userCard.getTemplate(context: context),
              let id = userCard.id else { return nil }
        
        return CardDisplayInfo(
            id: id,
            characterName: template.characterName ?? "Unknown",
            animeSeries: template.animeSeries ?? "Unknown",
            rarity: template.rarityEnum,
            level: userCard.level,
            isFavorite: userCard.isFavorite,
            obtainDate: userCard.obtainDate ?? Date(),
            attack: userCard.getCurrentAttack(context: context),
            defense: userCard.getCurrentDefense(context: context)
        )
    }
}
