import Foundation
import CoreData

// CardTemplate类的Core Data实现
// 卡片模板：定义所有可能的卡片类型和属性
@objc(CardTemplate)
public class CardTemplate: NSManagedObject {
    // Core Data自动生成的属性访问器
    @NSManaged public var id: UUID?
    @NSManaged public var animeSeries: String?
    @NSManaged public var characterName: String?
    @NSManaged public var rarity: Int16
    @NSManaged public var attackBonus: Int32
    @NSManaged public var defenseBonus: Int32
    @NSManaged public var cardDescription: String?
    @NSManaged public var imageUrl: String?
    @NSManaged public var isActive: Bool
    
    // 便捷初始化方法
    convenience init(context: NSManagedObjectContext, 
                     animeSeries: String,
                     characterName: String,
                     rarity: Rarity) {
        self.init(context: context)
        self.id = UUID()
        self.animeSeries = animeSeries
        self.characterName = characterName
        self.rarity = Int16(rarity.weight)
        self.attackBonus = Int32(rarity.attackBonus)
        self.defenseBonus = Int32(rarity.defenseBonus)
        self.cardDescription = "\(characterName) - \(animeSeries)\n稀有度：\(rarity.displayName)\n攻击：+\(rarity.attackBonus) 防御：+\(rarity.defenseBonus)"
        self.imageUrl = ""
        self.isActive = true
    }
    
    // 获取稀有度枚举
    var rarityEnum: Rarity {
        switch rarity {
        case 1: return .N
        case 2: return .R
        case 3: return .SR
        case 4: return .SSR
        default: return .N
        }
    }
    
    // 获取稀有度显示名称
    var rarityDisplayName: String {
        return rarityEnum.displayName
    }
    
    // 获取稀有度颜色
    var rarityColor: String {
        return rarityEnum.displayColor
    }
    
    // 获取卡片总属性值
    var totalStats: Int {
        return Int(attackBonus + defenseBonus)
    }
    
    // 获取格式化的卡片描述
    var formattedDescription: String {
        guard let charName = characterName, let series = animeSeries else {
            return "未知卡片"
        }
        return "\(charName) - \(series)\n稀有度：\(rarityDisplayName)\n攻击：+\(attackBonus) 防御：+\(defenseBonus)"
    }
    
    // 获取动漫系列枚举
    var animeSeriesEnum: AnimeSeries? {
        guard let series = animeSeries else { return nil }
        return AnimeSeries(rawValue: series)
    }
    
    // 检查是否是高稀有度卡片（SR或以上）
    var isHighRarity: Bool {
        return rarity >= 3
    }
    
    // 检查是否是SSR卡片
    var isSSR: Bool {
        return rarity == 4
    }
}

// 扩展Rarity枚举，添加属性值计算
extension Rarity {
    // 稀有度对应的卡牌属性加成
    var attackBonus: Int {
        switch self {
        case .N: return 10
        case .R: return 30
        case .SR: return 60
        case .SSR: return 100
        }
    }
    
    var defenseBonus: Int {
        switch self {
        case .N: return 5
        case .R: return 15
        case .SR: return 30
        case .SSR: return 50
        }
    }
}
