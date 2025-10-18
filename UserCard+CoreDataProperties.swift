import Foundation
import CoreData

extension UserCard {
    
    // 定义获取请求常量
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserCard> {
        return NSFetchRequest<UserCard>(entityName: "UserCard")
    }
    
    // 定义实体属性
    @NSManaged public var id: UUID?
    @NSManaged public var userId: UUID?
    @NSManaged public var templateId: UUID?
    @NSManaged public var obtainDate: Date?
    @NSManaged public var isBoosted: Bool
    @NSManaged public var level: Int16
    @NSManaged public var experience: Int32
    @NSManaged public var isFavorite: Bool
}

// 添加便捷的排序描述符
public extension UserCard {
    
    // 按获得时间排序（最新的在前）
    static var sortByObtainDateDescending: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "obtainDate", ascending: false)]
    }
    
    // 按获得时间排序（最早的在前）
    static var sortByObtainDateAscending: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "obtainDate", ascending: true)]
    }
    
    // 按等级排序（从高到低）
    static var sortByLevelDescending: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "level", ascending: false)]
    }
    
    // 按等级排序（从低到高）
    static var sortByLevelAscending: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "level", ascending: true)]
    }
    
    // 收藏的卡片优先
    static var sortByFavoriteFirst: [NSSortDescriptor] {
        return [
            NSSortDescriptor(key: "isFavorite", ascending: false),
            NSSortDescriptor(key: "obtainDate", ascending: false)
        ]
    }
}

// 添加查询条件便捷方法
extension UserCard {
    
    // 获取特定用户的卡片
    static func predicateForUser(userId: UUID) -> NSPredicate {
        return NSPredicate(format: "userId == %@", userId as CVarArg)
    }
    
    // 获取特定模板的卡片
    static func predicateForTemplate(templateId: UUID) -> NSPredicate {
        return NSPredicate(format: "templateId == %@", templateId as CVarArg)
    }
    
    // 获取今天获得的卡片
    static func predicateForToday() -> NSPredicate {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        return NSPredicate(format: "obtainDate >= %@ AND obtainDate < %@", today as CVarArg, tomorrow as CVarArg)
    }
    
    // 获取指定日期范围内获得的卡片
    static func predicateForDateRange(startDate: Date, endDate: Date) -> NSPredicate {
        return NSPredicate(format: "obtainDate >= %@ AND obtainDate <= %@", startDate as CVarArg, endDate as CVarArg)
    }
    
    // 获取收藏的卡片
    static var predicateForFavorites: NSPredicate {
        return NSPredicate(format: "isFavorite == YES")
    }
    
    // 获取通过概率提升获得的卡片
    static var predicateForBoosted: NSPredicate {
        return NSPredicate(format: "isBoosted == YES")
    }
    
    // 获取指定等级范围的卡片
    static func predicateForLevelRange(min: Int16, max: Int16) -> NSPredicate {
        return NSPredicate(format: "level >= %d AND level <= %d", min, max)
    }
    
    // 获取高等级卡片（20级以上）
    static var predicateForHighLevel: NSPredicate {
        return NSPredicate(format: "level >= 20")
    }
    
    // 组合查询：特定用户的收藏卡片
    static func predicateForUserFavorites(userId: UUID) -> NSPredicate {
        let userPredicate = predicateForUser(userId: userId)
        let favoritePredicate = predicateForFavorites
        return NSCompoundPredicate(andPredicateWithSubpredicates: [userPredicate, favoritePredicate])
    }
    
    // 组合查询：特定用户今天获得的卡片
    static func predicateForUserToday(userId: UUID) -> NSPredicate {
        let userPredicate = predicateForUser(userId: userId)
        let todayPredicate = predicateForToday()
        return NSCompoundPredicate(andPredicateWithSubpredicates: [userPredicate, todayPredicate])
    }
}

// 统计和分析方法
extension UserCard {
    
    // 统计用户拥有的卡片数量
    static func countUserCards(userId: UUID, context: NSManagedObjectContext) -> Int {
        let request: NSFetchRequest<UserCard> = UserCard.fetchRequest()
        request.predicate = predicateForUser(userId: userId)
        
        do {
            return try context.count(for: request)
        } catch {
            print("Error counting user cards: \(error)")
            return 0
        }
    }
    
    // 统计用户按稀有度拥有的卡片数量
    static func countByRarity(userId: UUID, context: NSManagedObjectContext) -> [Rarity: Int] {
        var counts: [Rarity: Int] = [.N: 0, .R: 0, .SR: 0, .SSR: 0]
        
        let request: NSFetchRequest<UserCard> = UserCard.fetchRequest()
        request.predicate = predicateForUser(userId: userId)
        
        do {
            let userCards = try context.fetch(request)
            
            for userCard in userCards {
                let rarity = userCard.getRarity(context: context)
                counts[rarity, default: 0] += 1
            }
        } catch {
            print("Error counting cards by rarity: \(error)")
        }
        
        return counts
    }
    
    // 获取用户的平均卡片等级
    static func averageLevel(userId: UUID, context: NSManagedObjectContext) -> Double {
        let request: NSFetchRequest<UserCard> = UserCard.fetchRequest()
        request.predicate = predicateForUser(userId: userId)
        
        do {
            let userCards = try context.fetch(request)
            guard !userCards.isEmpty else { return 0 }
            
            let totalLevel = userCards.reduce(0) { $0 + Int($1.level) }
            return Double(totalLevel) / Double(userCards.count)
        } catch {
            print("Error calculating average level: \(error)")
            return 0
        }
    }
    
    // 获取用户的最高等级卡片
    static func highestLevelCard(userId: UUID, context: NSManagedObjectContext) -> UserCard? {
        let request: NSFetchRequest<UserCard> = UserCard.fetchRequest()
        request.predicate = predicateForUser(userId: userId)
        request.sortDescriptors = sortByLevelDescending
        request.fetchLimit = 1
        
        do {
            let cards = try context.fetch(request)
            return cards.first
        } catch {
            print("Error fetching highest level card: \(error)")
            return nil
        }
    }
    
    // 检查用户是否拥有特定模板的卡片
    static func hasTemplate(userId: UUID, templateId: UUID, context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<UserCard> = UserCard.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicateForUser(userId: userId),
            predicateForTemplate(templateId: templateId)
        ])
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("Error checking template ownership: \(error)")
            return false
        }
    }
    
    // 获取用户的收藏数量
    static func favoriteCount(userId: UUID, context: NSManagedObjectContext) -> Int {
        let request: NSFetchRequest<UserCard> = UserCard.fetchRequest()
        request.predicate = predicateForUserFavorites(userId: userId)
        
        do {
            return try context.count(for: request)
        } catch {
            print("Error counting favorites: \(error)")
            return 0
        }
    }
    
    // 批量设置收藏状态
    static func toggleFavorite(cardId: UUID, context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<UserCard> = UserCard.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", cardId as CVarArg)
        request.fetchLimit = 1
        
        do {
            if let card = try context.fetch(request).first {
                card.isFavorite.toggle()
                try context.save()
                return true
            }
        } catch {
            print("Error toggling favorite: \(error)")
        }
        
        return false
    }
}
