import Foundation
import CoreData

extension DrawRecord {
    
    // 定义获取请求常量
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DrawRecord> {
        return NSFetchRequest<DrawRecord>(entityName: "DrawRecord")
    }
    
    // 定义实体属性
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var userCardId: UUID?
    @NSManaged public var userId: UUID?
    @NSManaged public var drawType: String?
}

// 添加便捷的排序描述符
public extension DrawRecord {
    
    // 按抽卡时间排序（最新的在前）
    static var sortByTimestampDescending: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "timestamp", ascending: false)]
    }
    
    // 按抽卡时间排序（最早的在前）
    static var sortByTimestampAscending: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "timestamp", ascending: true)]
    }
}

// 添加查询条件便捷方法
extension DrawRecord {
    
    // 获取特定日期范围内的抽卡记录
    static func predicateForDateRange(startDate: Date, endDate: Date) -> NSPredicate {
        return NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startDate as CVarArg, endDate as CVarArg)
    }
    
    // 获取特定用户的抽卡记录
    static func predicateForUser(userId: UUID) -> NSPredicate {
        return NSPredicate(format: "userId == %@", userId as CVarArg)
    }
    
    // 获取今天的抽卡记录
    static func predicateForToday() -> NSPredicate {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        return predicateForDateRange(startDate: today, endDate: tomorrow)
    }
    
    // 获取指定天数内的抽卡记录
    static func predicateForLastNDays(_ days: Int) -> NSPredicate {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        return predicateForDateRange(startDate: startDate, endDate: endDate)
    }
    
    // 获取本周的抽卡记录
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
    
    // 获取本月的抽卡记录
    static func predicateForThisMonth() -> NSPredicate {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return NSPredicate(value: false)
        }
        
        return predicateForDateRange(startDate: startOfMonth, endDate: endOfMonth)
    }
}
