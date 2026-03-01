import Foundation
import CoreData

// Usage Time Monitor - Simplified version for demo
// Note: Real ScreenTime API requires device and entitlements
class UsageTimeMonitor {
    static let shared = UsageTimeMonitor()
    private init() {}
    
    // Simulated screen time for demo purposes
    private var simulatedUsageTime: TimeInterval = 2 * 3600 // 2 hours in seconds
    
    // Get simulated usage time
    func getCurrentUsageTime() -> TimeInterval {
        return simulatedUsageTime
    }
    
    // Set simulated usage time (for testing)
    func setSimulatedUsageTime(hours: Double) {
        simulatedUsageTime = hours * 3600
    }
    
    // Record usage to Core Data
    func recordUsage(userId: UUID) {
        let context = PersistenceController.shared.container.viewContext
        let record = UsageRecord(context: context, duration: simulatedUsageTime, userId: userId)
        
        do {
            try context.save()
        } catch {
            print("Error saving usage record: \(error)")
        }
    }
    
    // Get today's total usage time from records
    func getTodayUsageTime(userId: UUID) -> TimeInterval {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<UsageRecord> = UsageRecord.fetchRequest()
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "date >= %@ AND date < %@", today as CVarArg, tomorrow as CVarArg),
            NSPredicate(format: "userId == %@", userId as CVarArg)
        ])
        
        do {
            let records = try context.fetch(request)
            return records.reduce(0) { $0 + $1.duration }
        } catch {
            print("Error fetching usage records: \(error)")
            return simulatedUsageTime
        }
    }
}