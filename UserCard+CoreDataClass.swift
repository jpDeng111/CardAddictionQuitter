import Foundation
import CoreData

// UserCard类的Core Data实现
// 用户卡片：用户实际拥有的卡片实例
@objc(UserCard)
public class UserCard: NSManagedObject {
    // Core Data自动生成的属性访问器
    @NSManaged public var id: UUID?
    @NSManaged public var userId: UUID?
    @NSManaged public var templateId: UUID?
    @NSManaged public var obtainDate: Date?
    @NSManaged public var isBoosted: Bool
    @NSManaged public var level: Int16
    @NSManaged public var experience: Int32
    @NSManaged public var isFavorite: Bool
    
    // 便捷初始化方法
    convenience init(context: NSManagedObjectContext,
                     userId: UUID,
                     templateId: UUID,
                     isBoosted: Bool = false) {
        self.init(context: context)
        self.id = UUID()
        self.userId = userId
        self.templateId = templateId
        self.obtainDate = Date()
        self.isBoosted = isBoosted
        self.level = 1
        self.experience = 0
        self.isFavorite = false
    }
    
    // 获取关联的卡片模板
    func getTemplate(context: NSManagedObjectContext) -> CardTemplate? {
        guard let templateId = templateId else { return nil }
        
        let request: NSFetchRequest<CardTemplate> = CardTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", templateId as CVarArg)
        request.fetchLimit = 1
        
        do {
            let templates = try context.fetch(request)
            return templates.first
        } catch {
            print("Error fetching card template: \(error)")
            return nil
        }
    }
    
    // 获取卡片稀有度
    func getRarity(context: NSManagedObjectContext) -> Rarity {
        guard let template = getTemplate(context: context) else {
            return .N
        }
        return template.rarityEnum
    }
    
    // 获取卡片名称
    func getCardName(context: NSManagedObjectContext) -> String {
        guard let template = getTemplate(context: context),
              let charName = template.characterName else {
            return "未知卡片"
        }
        return charName
    }
    
    // 获取动漫系列
    func getAnimeSeries(context: NSManagedObjectContext) -> String {
        guard let template = getTemplate(context: context),
              let series = template.animeSeries else {
            return "未知系列"
        }
        return series
    }
    
    // 获取当前卡片总属性值（包含等级加成）
    func getTotalStats(context: NSManagedObjectContext) -> Int {
        guard let template = getTemplate(context: context) else {
            return 0
        }
        
        let baseStats = Int(template.attackBonus + template.defenseBonus)
        let levelBonus = Int(level - 1) * 10 // 每级增加10点属性
        return baseStats + levelBonus
    }
    
    // 获取当前攻击力（包含等级加成）
    func getCurrentAttack(context: NSManagedObjectContext) -> Int {
        guard let template = getTemplate(context: context) else {
            return 0
        }
        
        let levelBonus = Int(level - 1) * 6 // 每级增加6点攻击
        return Int(template.attackBonus) + levelBonus
    }
    
    // 获取当前防御力（包含等级加成）
    func getCurrentDefense(context: NSManagedObjectContext) -> Int {
        guard let template = getTemplate(context: context) else {
            return 0
        }
        
        let levelBonus = Int(level - 1) * 4 // 每级增加4点防御
        return Int(template.defenseBonus) + levelBonus
    }
    
    // 获取升到下一级所需经验
    var experienceNeeded: Int32 {
        return Int32(level) * 100 // 每级需要 等级*100 经验
    }
    
    // 获取经验进度百分比
    var experienceProgress: Double {
        let needed = experienceNeeded
        guard needed > 0 else { return 1.0 }
        return Double(experience) / Double(needed)
    }
    
    // 添加经验值（可能升级）
    func addExperience(_ amount: Int32, context: NSManagedObjectContext) -> Bool {
        experience += amount
        var didLevelUp = false
        
        // 检查是否可以升级
        while experience >= experienceNeeded && level < 100 {
            experience -= experienceNeeded
            level += 1
            didLevelUp = true
        }
        
        // 保存变更
        do {
            try context.save()
        } catch {
            print("Error saving level up: \(error)")
        }
        
        return didLevelUp
    }
    
    // 检查是否是今天获得的
    var isObtainedToday: Bool {
        guard let obtainDate = obtainDate else {
            return false
        }
        
        let calendar = Calendar.current
        return calendar.isDateInToday(obtainDate)
    }
    
    // 获取格式化的获得时间
    var formattedObtainDate: String {
        guard let obtainDate = obtainDate else {
            return "未知时间"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current
        
        return dateFormatter.string(from: obtainDate)
    }
    
    // 获取卡片详细描述
    func getDetailedDescription(context: NSManagedObjectContext) -> String {
        guard let template = getTemplate(context: context) else {
            return "卡片信息加载失败"
        }
        
        var desc = "\(template.characterName ?? "未知") - \(template.animeSeries ?? "未知")\n"
        desc += "稀有度：\(template.rarityDisplayName)\n"
        desc += "等级：Lv.\(level)\n"
        desc += "攻击：\(getCurrentAttack(context: context)) 防御：\(getCurrentDefense(context: context))\n"
        desc += "经验：\(experience)/\(experienceNeeded)\n"
        
        if isBoosted {
            desc += "⭐ 概率提升获得"
        }
        
        return desc
    }
}
