import Foundation
import CoreData

// DrawRecord类的Core Data实现
@objc(DrawRecord)
public class DrawRecord: NSManagedObject {
    // Core Data自动生成的属性访问器
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var userCardId: UUID?  // 关联UserCard.id
    @NSManaged public var userId: UUID?      // 关联User.id
    @NSManaged public var drawType: String?  // single/multi
    
    // 便捷初始化方法
    convenience init(context: NSManagedObjectContext, 
                     userCardId: UUID, 
                     userId: UUID,
                     drawType: DrawType = .single) {
        self.init(context: context)
        self.id = UUID()
        self.timestamp = Date()
        self.userCardId = userCardId
        self.userId = userId
        self.drawType = drawType.rawValue
    }
    
    // 获取关联的用户卡片
    func getUserCard(context: NSManagedObjectContext) -> UserCard? {
        guard let userCardId = userCardId else { return nil }
        
        let request: NSFetchRequest<UserCard> = UserCard.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", userCardId as CVarArg)
        request.fetchLimit = 1
        
        do {
            let cards = try context.fetch(request)
            return cards.first
        } catch {
            print("Error fetching user card: \(error)")
            return nil
        }
    }
    
    // 获取抽卡类型枚举
    var drawTypeEnum: DrawType {
        guard let type = drawType else { return .single }
        return DrawType(rawValue: type) ?? .single
    }
    
    // 检查是否是今天的抽卡记录
    var isToday: Bool {
        guard let timestamp = timestamp else {
            return false
        }
        
        let calendar = Calendar.current
        return calendar.isDateInToday(timestamp)
    }
    
    // 获取格式化的抽卡时间
    var formattedTimestamp: String {
        guard let timestamp = timestamp else {
            return "未知时间"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current
        
        return dateFormatter.string(from: timestamp)
    }
    
    // 获取相对时间描述（如"5分钟前"）
    var relativeTimeDescription: String {
        guard let timestamp = timestamp else {
            return "未知时间"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale.current
        
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    // 获取抽卡时间的小时数（用于统计）
    var hourOfDay: Int {
        guard let timestamp = timestamp else {
            return 0
        }
        
        let calendar = Calendar.current
        return calendar.component(.hour, from: timestamp)
    }
}

// 抽卡类型枚举
enum DrawType: String, CaseIterable {
    case single = "single"  // 单抽
    case multi = "multi"    // 10连抽
    
    var displayName: String {
        switch self {
        case .single: return "单抽"
        case .multi: return "10连抽"
        }
    }
}
