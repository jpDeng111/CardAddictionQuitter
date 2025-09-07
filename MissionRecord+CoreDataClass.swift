import Foundation
import CoreData

// MissionRecord类的Core Data实现
@objc(MissionRecord)
public class MissionRecord: NSManagedObject {
    // Core Data自动生成的属性访问器
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var completedDate: Date?
    @NSManaged public var probabilityBoost: Double
    
    // 从MissionType创建MissionRecord的便捷方法
    convenience init(context: NSManagedObjectContext, missionType: MissionType) {
        self.init(context: context)
        self.id = UUID()
        self.type = missionType.rawValue
        self.completedDate = Date()
        self.probabilityBoost = missionType.probabilityBoost
    }
    
    // 获取关联的MissionType
    var missionType: MissionType? {
        guard let type = type else {
            return nil
        }
        return MissionType(rawValue: type)
    }
    
    // 获取任务名称
    var missionName: String {
        return missionType?.name ?? "未知任务"
    }
    
    // 获取任务描述
    var missionDescription: String {
        return missionType?.description ?? "无描述"
    }
    
    // 检查是否是今天完成的任务
    var isToday: Bool {
        guard let completedDate = completedDate else {
            return false
        }
        
        let calendar = Calendar.current
        return calendar.isDateInToday(completedDate)
    }
    
    // 获取任务完成的格式化时间
    var formattedCompletedTime: String {
        guard let completedDate = completedDate else {
            return "未知时间"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current
        
        return dateFormatter.string(from: completedDate)
    }
    
    // 获取概率提升的百分比表示
    var formattedProbabilityBoost: String {
        let percentage = Int(probabilityBoost * 100)
        return "+\(percentage)%"
    }
}