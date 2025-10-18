import Foundation
import CoreData

extension CardTemplate {
    
    // 定义获取请求常量
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CardTemplate> {
        return NSFetchRequest<CardTemplate>(entityName: "CardTemplate")
    }
    
    // 定义实体属性
    @NSManaged public var id: UUID?
    @NSManaged public var animeSeries: String?
    @NSManaged public var characterName: String?
    @NSManaged public var rarity: Int16
    @NSManaged public var attackBonus: Int32
    @NSManaged public var defenseBonus: Int32
    @NSManaged public var cardDescription: String?
    @NSManaged public var imageUrl: String?
    @NSManaged public var isActive: Bool
}

// 添加便捷的排序描述符
public extension CardTemplate {
    
    // 按稀有度排序（从高到低）
    static var sortByRarityDescending: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "rarity", ascending: false)]
    }
    
    // 按稀有度排序（从低到高）
    static var sortByRarityAscending: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "rarity", ascending: true)]
    }
    
    // 按角色名称排序
    static var sortByCharacterName: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "characterName", ascending: true)]
    }
    
    // 按动漫系列排序
    static var sortByAnimeSeries: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "animeSeries", ascending: true)]
    }
    
    // 按总属性值排序（从高到低）
    static var sortByTotalStats: [NSSortDescriptor] {
        return [
            NSSortDescriptor(key: "attackBonus", ascending: false),
            NSSortDescriptor(key: "defenseBonus", ascending: false)
        ]
    }
}

// 添加查询条件便捷方法
extension CardTemplate {
    
    // 获取特定稀有度的卡片模板
    static func predicateForRarity(_ rarity: Rarity) -> NSPredicate {
        return NSPredicate(format: "rarity == %d", rarity.weight)
    }
    
    // 获取特定动漫系列的卡片模板
    static func predicateForAnimeSeries(_ series: AnimeSeries) -> NSPredicate {
        return NSPredicate(format: "animeSeries == %@", series.rawValue)
    }
    
    // 获取特定角色的卡片模板
    static func predicateForCharacter(_ characterName: String) -> NSPredicate {
        return NSPredicate(format: "characterName == %@", characterName)
    }
    
    // 获取启用状态的卡片模板
    static var predicateForActive: NSPredicate {
        return NSPredicate(format: "isActive == YES")
    }
    
    // 获取高稀有度卡片（SR及以上）
    static var predicateForHighRarity: NSPredicate {
        return NSPredicate(format: "rarity >= 3")
    }
    
    // 获取SSR卡片
    static var predicateForSSR: NSPredicate {
        return NSPredicate(format: "rarity == 4")
    }
    
    // 获取指定稀有度范围的卡片
    static func predicateForRarityRange(min: Int16, max: Int16) -> NSPredicate {
        return NSPredicate(format: "rarity >= %d AND rarity <= %d", min, max)
    }
    
    // 组合查询：特定动漫系列且启用的卡片
    static func predicateForActiveInSeries(_ series: AnimeSeries) -> NSPredicate {
        let seriesPredicate = predicateForAnimeSeries(series)
        let activePredicate = predicateForActive
        return NSCompoundPredicate(andPredicateWithSubpredicates: [seriesPredicate, activePredicate])
    }
}

// 统计和工具方法
extension CardTemplate {
    
    // 统计各稀有度的卡片数量
    static func countByRarity(context: NSManagedObjectContext) -> [Rarity: Int] {
        var counts: [Rarity: Int] = [.N: 0, .R: 0, .SR: 0, .SSR: 0]
        
        for rarity in Rarity.allCases {
            let request: NSFetchRequest<CardTemplate> = CardTemplate.fetchRequest()
            request.predicate = predicateForRarity(rarity)
            
            do {
                let count = try context.count(for: request)
                counts[rarity] = count
            } catch {
                print("Error counting templates for rarity \(rarity): \(error)")
            }
        }
        
        return counts
    }
    
    // 统计各动漫系列的卡片数量
    static func countByAnimeSeries(context: NSManagedObjectContext) -> [AnimeSeries: Int] {
        var counts: [AnimeSeries: Int] = [:]
        
        for series in AnimeSeries.allCases {
            let request: NSFetchRequest<CardTemplate> = CardTemplate.fetchRequest()
            request.predicate = predicateForAnimeSeries(series)
            
            do {
                let count = try context.count(for: request)
                counts[series] = count
            } catch {
                print("Error counting templates for series \(series): \(error)")
            }
        }
        
        return counts
    }
    
    // 获取随机卡片模板（按稀有度）
    static func randomTemplate(rarity: Rarity, context: NSManagedObjectContext) -> CardTemplate? {
        let request: NSFetchRequest<CardTemplate> = CardTemplate.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicateForRarity(rarity),
            predicateForActive
        ])
        
        do {
            let templates = try context.fetch(request)
            return templates.randomElement()
        } catch {
            print("Error fetching random template: \(error)")
            return nil
        }
    }
    
    // 获取所有启用的卡片模板
    static func fetchAllActive(context: NSManagedObjectContext) -> [CardTemplate] {
        let request: NSFetchRequest<CardTemplate> = CardTemplate.fetchRequest()
        request.predicate = predicateForActive
        request.sortDescriptors = sortByRarityDescending
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching active templates: \(error)")
            return []
        }
    }
}
