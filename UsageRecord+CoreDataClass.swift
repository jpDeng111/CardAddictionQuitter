import Foundation
import CoreData

// UsageRecord类的Core Data实现
@objc(UsageRecord)
public class UsageRecord: NSManagedObject {
    // Core Data自动生成的属性访问器
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var duration: Double  // 使用时长（秒）
    @NSManaged public var userId: UUID?
    
    // 便捷初始化方法
    convenience init(context: NSManagedObjectContext, duration: Double, userId: UUID) {
        self.init(context: context)
        self.id = UUID()
        self.date = Date()
        self.duration = duration
        self.userId = userId
    }
    
    // 获取使用时长（小时）
    var durationInHours: Double {
        return duration / 3600.0
    }
    
    // 获取使用时长（分钟）
    var durationInMinutes: Double {
        return duration / 60.0
    }
    
    // 获取格式化的使用时长
    var formattedDuration: String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%d小时%d分钟", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%d分钟%d秒", minutes, seconds)
        } else {
            return String(format: "%d秒", seconds)
        }
    }
    
    // 获取格式化的日期
    var formattedDate: String {
        guard let date = date else {
            return "未知日期"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current
        
        return dateFormatter.string(from: date)
    }
    
    // 检查是否是今天的记录
    var isToday: Bool {
        guard let date = date else {
            return false
        }
        
        let calendar = Calendar.current
        return calendar.isDateInToday(date)
    }
    
    // 检查使用时长是否超标（超过3小时）
    var isOverLimit: Bool {
        return durationInHours > 3.0
    }
    
    // 检查是否达到优秀标准（低于1.5小时）
    var isExcellent: Bool {
        return durationInHours <= 1.5
    }
    
    // 获取使用时长的评级
    var usageRating: String {
        let hours = durationInHours
        
        if hours <= 1.5 {
            return "优秀"
        } else if hours <= 3.0 {
            return "良好"
        } else if hours <= 5.0 {
            return "一般"
        } else {
            return "需要改善"
        }
    }
    
    // 获取使用时长的颜色标识（用于UI显示）
    var ratingColor: String {
        let hours = durationInHours
        
        if hours <= 1.5 {
            return "#00FF00"  // 绿色
        } else if hours <= 3.0 {
            return "#FFA500"  // 橙色
        } else if hours <= 5.0 {
            return "#FF6600"  // 深橙色
        } else {
            return "#FF0000"  // 红色
        }
    }
}
