import Foundation
import CoreData

extension UsageRecord {
    
    // 定义获取请求常量
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UsageRecord> {
        return NSFetchRequest<UsageRecord>(entityName: "UsageRecord")
    }
    
    // 定义实体属性
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var duration: Double
    @NSManaged public var userId: UUID?
}

// 添加便捷的排序描述符
public extension UsageRecord {
    
    // 按日期排序（最新的在前）
    static var sortByDateDescending: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "date", ascending: false)]
    }
    
    // 按日期排序（最早的在前）
    static var sortByDateAscending: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "date", ascending: true)]
    }
    
    // 按使用时长排序（从高到低）
    static var sortByDurationDescending: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "duration", ascending: false)]
    }
    
    // 按使用时长排序（从低到高）
    static var sortByDurationAscending: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "duration", ascending: true)]
    }
}

// 添加查询条件便捷方法
extension UsageRecord {
    
    // 获取特定日期范围内的使用记录
    static func predicateForDateRange(startDate: Date, endDate: Date) -> NSPredicate {
        return NSPredicate(format: "date >= %@ AND date <= %@", startDate as CVarArg, endDate as CVarArg)
    }
    
    // 获取特定用户的使用记录
    static func predicateForUser(userId: UUID) -> NSPredicate {
        return NSPredicate(format: "userId == %@", userId as CVarArg)
    }
    
    // 获取今天的使用记录
    static func predicateForToday() -> NSPredicate {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        return predicateForDateRange(startDate: today, endDate: tomorrow)
    }
    
    // 获取指定天数内的使用记录
    static func predicateForLastNDays(_ days: Int) -> NSPredicate {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        return predicateForDateRange(startDate: startDate, endDate: endDate)
    }
    
    // 获取本周的使用记录
    static func predicateForThisWeek() -> NSPredicate {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let daysToMonday = (weekday == 1) ? 6 : weekday - 2
        
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysToMonday, to: calendar.startOfDay(for: now)),
              let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else {
            return NSPredicate(value: false)
        }
        
        return predicateForDateRange(startDate: startOfWeek, endDate: endOfWeek)
    }
    
    // 获取本月的使用记录
    static func predicateForThisMonth() -> NSPredicate {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return NSPredicate(value: false)
        }
        
        return predicateForDateRange(startDate: startOfMonth, endDate: endOfMonth)
    }
    
    // 获取使用时长超标的记录（超过3小时）
    static func predicateForOverLimit() -> NSPredicate {
        return NSPredicate(format: "duration > %f", 3.0 * 3600)
    }
    
    // 获取使用时长优秀的记录（低于1.5小时）
    static func predicateForExcellent() -> NSPredicate {
        return NSPredicate(format: "duration <= %f", 1.5 * 3600)
    }
    
    // 组合查询：获取特定用户今天的使用记录
    static func predicateForUserToday(userId: UUID) -> NSPredicate {
        let userPredicate = predicateForUser(userId: userId)
        let todayPredicate = predicateForToday()
        return NSCompoundPredicate(andPredicateWithSubpredicates: [userPredicate, todayPredicate])
    }
}

// 统计分析扩展
extension UsageRecord {
    
    // 计算平均使用时长（从记录列表）
    static func calculateAverageDuration(from records: [UsageRecord]) -> Double {
        guard !records.isEmpty else { return 0 }
        let total = records.reduce(0.0) { $0 + $1.duration }
        return total / Double(records.count)
    }
    
    // 计算总使用时长（从记录列表）
    static func calculateTotalDuration(from records: [UsageRecord]) -> Double {
        return records.reduce(0.0) { $0 + $1.duration }
    }
    
    // 获取最长使用时长记录
    static func findLongestUsage(from records: [UsageRecord]) -> UsageRecord? {
        return records.max(by: { $0.duration < $1.duration })
    }
    
    // 获取最短使用时长记录
    static func findShortestUsage(from records: [UsageRecord]) -> UsageRecord? {
        return records.min(by: { $0.duration < $1.duration })
    }
}
