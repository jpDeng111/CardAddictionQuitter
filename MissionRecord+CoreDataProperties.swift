import Foundation
import CoreData

extension MissionRecord {
    
    // 定义获取请求常量
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MissionRecord> {
        return NSFetchRequest<MissionRecord>(entityName: "MissionRecord")
    }
    
    // 定义实体属性
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var completedDate: Date?
    @NSManaged public var probabilityBoost: Double
}

// 添加便捷的排序描述符
public extension MissionRecord {
    
    // 按完成日期排序（最新的在前）
    static var sortByCompletedDateDescending: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "completedDate", ascending: false)]
    }
    
    // 按完成日期排序（最早的在前）
    static var sortByCompletedDateAscending: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "completedDate", ascending: true)]
    }
    
    // 按概率提升值排序（从高到低）
    static var sortByProbabilityBoostDescending: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "probabilityBoost", ascending: false)]
    }
}

// 添加查询条件便捷方法
extension MissionRecord {
    
    // 获取特定日期范围内的任务记录
    static func predicateForDateRange(startDate: Date, endDate: Date) -> NSPredicate {
        return NSPredicate(format: "completedDate >= %@ AND completedDate <= %@", startDate as CVarArg, endDate as CVarArg)
    }
    
    // 获取特定类型的任务记录
    static func predicateForMissionType(_ type: MissionType) -> NSPredicate {
        return NSPredicate(format: "type == %@", type.rawValue)
    }
    
    // 获取今天的任务记录
    static func predicateForToday() -> NSPredicate {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        return predicateForDateRange(startDate: today, endDate: tomorrow)
    }
    
    // 获取指定天数内的任务记录
    static func predicateForLastNDays(_ days: Int) -> NSPredicate {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        return predicateForDateRange(startDate: startDate, endDate: endDate)
    }
}