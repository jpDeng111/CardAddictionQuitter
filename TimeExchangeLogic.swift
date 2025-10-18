import Foundation
import CoreData

// 抽卡时间兑换逻辑系统
class TimeExchangeManager {
    // 单例模式
    static let shared = TimeExchangeManager()
    private init() {}
    
    // 基础配置常量
    private let baseDrawChances = 5  // 基础抽卡次数（3小时内）
    private let penaltyPerHour = 1   // 每小时惩罚次数
    private let maxDailyDraws = 10   // 每日最大抽卡次数上限
    private let bonusThreshold = 1.5 // 1.5小时内额外奖励阈值
    private let bonusDraws = 2       // 提前完成目标的额外奖励抽卡次数
    
    // 计算当日可获得的抽卡次数
    func calculateDrawChances(usageHours: Double) -> Int {
        // 基础计算逻辑
        let penalty = max(0, Int(usageHours) - 3)
        var availableDraws = baseDrawChances - penalty
        
        // 确保抽卡次数不为负
        availableDraws = max(0, availableDraws)
        
        // 如果用户控制在1.5小时内，额外奖励2次抽卡
        if usageHours <= bonusThreshold {
            availableDraws += bonusDraws
        }
        
        // 检查是否已经达到每日上限
        let todayUsedDraws = getTodayUsedDraws()
        let remainingDraws = max(0, maxDailyDraws - todayUsedDraws)
        
        return min(availableDraws, remainingDraws)
    }
    
    // 获取当日已使用的抽卡次数
    private func getTodayUsedDraws(userId: UUID) -> Int {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<DrawRecord> = DrawRecord.fetchRequest()
        
        // 只查询今天的记录
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "timestamp >= %@ AND timestamp < %@", today as CVarArg, tomorrow as CVarArg),
            NSPredicate(format: "userId == %@", userId as CVarArg)
        ])
        
        do {
            let records = try context.fetch(request)
            return records.count
        } catch {
            print("Error fetching draw records: \(error)")
            return 0
        }
    }
    
    // 记录抽卡行为
    func recordDrawUsage(userId: UUID) -> Bool {
        let context = PersistenceController.shared.container.viewContext
        
        // 检查是否还有剩余抽卡次数
        if let todayUsage = getTodayScreenTime(userId: userId) {
            let availableDraws = calculateDrawChances(usageHours: todayUsage)
            let usedDraws = getTodayUsedDraws(userId: userId)
            
            if usedDraws >= availableDraws || usedDraws >= maxDailyDraws {
                return false // 没有可用抽卡次数了
            }
        }
        
        return true // 可以抽卡
    }
    
    // 获取今日屏幕使用时间
    private func getTodayScreenTime(userId: UUID) -> Double? {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<UsageRecord> = UsageRecord.fetchRequest()
        
        // 只查询今天的记录
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "date >= %@ AND date < %@", today as CVarArg, tomorrow as CVarArg),
            NSPredicate(format: "userId == %@", userId as CVarArg)
        ])
        
        do {
            let records = try context.fetch(request)
            // 计算今日总使用时间（小时）
            let totalSeconds = records.reduce(0) { $0 + $1.duration }
            return totalSeconds / 3600
        } catch {
            print("Error fetching usage records: \(error)")
            return nil
        }
    }
    
    // 获取今日剩余抽卡次数
    func getRemainingDrawsForToday(userId: UUID) -> Int {
        guard let todayUsage = getTodayScreenTime(userId: userId) else {
            return 0
        }
        
        let availableDraws = calculateDrawChances(usageHours: todayUsage)
        let usedDraws = getTodayUsedDraws(userId: userId)
        
        return max(0, availableDraws - usedDraws)
    }
    
    // 获取使用时间进度信息（用于UI显示）
    func getProgressInfo() -> (currentHours: Double, targetHours: Double, progressPercentage: Double) {
        let todayUsage = getTodayScreenTime() ?? 0
        let targetHours = 3.0 // 目标控制在3小时内
        let progressPercentage = min(1.0, todayUsage / targetHours)
        
        return (currentHours: todayUsage, targetHours: targetHours, progressPercentage: progressPercentage)
    }
}