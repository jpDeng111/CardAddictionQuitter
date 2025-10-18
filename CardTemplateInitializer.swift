import Foundation
import CoreData

// 卡片模板初始化器
// 负责在首次启动时创建所有卡片模板
class CardTemplateInitializer {
    
    static let shared = CardTemplateInitializer()
    private init() {}
    
    // 初始化所有卡片模板
    func initializeTemplates(context: NSManagedObjectContext) {
        // 检查是否已经初始化过
        let request: NSFetchRequest<CardTemplate> = CardTemplate.fetchRequest()
        
        do {
            let count = try context.count(for: request)
            if count > 0 {
                print("✅ 卡片模板已存在，跳过初始化")
                return
            }
        } catch {
            print("Error checking templates: \(error)")
            return
        }
        
        print("🎴 开始初始化卡片模板...")
        
        // 为每个动漫系列创建角色卡片
        for series in AnimeSeries.allCases {
            createTemplatesForSeries(series, context: context)
        }
        
        // 保存所有模板
        do {
            try context.save()
            let finalCount = try context.count(for: request)
            print("✅ 卡片模板初始化完成！共创建 \(finalCount) 张卡片")
        } catch {
            print("❌ 保存模板失败: \(error)")
        }
    }
    
    // 为特定动漫系列创建卡片模板
    private func createTemplatesForSeries(_ series: AnimeSeries, context: NSManagedObjectContext) {
        let characters = series.characters
        
        // 为每个角色创建不同稀有度的卡片
        for character in characters {
            // 根据角色索引分配稀有度
            let characterIndex = characters.firstIndex(of: character) ?? 0
            
            // 每个角色有多个稀有度版本
            let rarities = assignRarities(characterIndex: characterIndex, totalCharacters: characters.count)
            
            for rarity in rarities {
                createTemplate(series: series, character: character, rarity: rarity, context: context)
            }
        }
    }
    
    // 分配稀有度（确保合理的稀有度分布）
    private func assignRarities(characterIndex: Int, totalCharacters: Int) -> [Rarity] {
        var rarities: [Rarity] = []
        
        // 所有角色都有N卡
        rarities.append(.N)
        
        // 大部分角色有R卡
        if characterIndex < totalCharacters * 4 / 5 {
            rarities.append(.R)
        }
        
        // 一半角色有SR卡
        if characterIndex < totalCharacters / 2 {
            rarities.append(.SR)
        }
        
        // 少数角色有SSR卡（主角和重要角色）
        if characterIndex < totalCharacters / 3 {
            rarities.append(.SSR)
        }
        
        return rarities
    }
    
    // 创建单个卡片模板
    private func createTemplate(series: AnimeSeries, character: String, rarity: Rarity, context: NSManagedObjectContext) {
        let template = CardTemplate(context: context,
                                   animeSeries: series.rawValue,
                                   characterName: character,
                                   rarity: rarity)
        
        // 根据稀有度添加特殊描述
        let specialDesc = getSpecialDescription(character: character, rarity: rarity, series: series)
        if !specialDesc.isEmpty {
            template.cardDescription = specialDesc
        }
        
        print("  创建模板: \(series.rawValue) - \(character) [\(rarity.displayName)]")
    }
    
    // 获取特殊描述（可根据角色自定义）
    private func getSpecialDescription(character: String, rarity: Rarity, series: AnimeSeries) -> String {
        var desc = "\(character) - \(series.rawValue)\n"
        desc += "稀有度：\(rarity.displayName)\n"
        
        // 根据稀有度添加描述
        switch rarity {
        case .SSR:
            desc += "⭐⭐⭐⭐ 传说级角色！\n"
        case .SR:
            desc += "⭐⭐⭐ 强力角色！\n"
        case .R:
            desc += "⭐⭐ 优秀角色\n"
        case .N:
            desc += "⭐ 基础角色\n"
        }
        
        desc += "攻击：+\(rarity.attackBonus) 防御：+\(rarity.defenseBonus)"
        
        return desc
    }
    
    // 获取模板统计信息
    func getTemplateStatistics(context: NSManagedObjectContext) -> String {
        var stats = "📊 卡片模板统计：\n"
        stats += "==================\n"
        
        // 按稀有度统计
        let rarityCounts = CardTemplate.countByRarity(context: context)
        stats += "\n按稀有度分布：\n"
        for rarity in [Rarity.SSR, .SR, .R, .N] {
            stats += "  \(rarity.displayName): \(rarityCounts[rarity] ?? 0)张\n"
        }
        
        // 按系列统计
        let seriesCounts = CardTemplate.countByAnimeSeries(context: context)
        stats += "\n按动漫系列分布：\n"
        for series in AnimeSeries.allCases {
            stats += "  \(series.rawValue): \(seriesCounts[series] ?? 0)张\n"
        }
        
        // 总计
        let request: NSFetchRequest<CardTemplate> = CardTemplate.fetchRequest()
        do {
            let total = try context.count(for: request)
            stats += "\n总计: \(total)张模板\n"
        } catch {
            stats += "\n统计错误: \(error)\n"
        }
        
        stats += "=================="
        return stats
    }
    
    // 重置所有模板（谨慎使用）
    func resetAllTemplates(context: NSManagedObjectContext) {
        let request: NSFetchRequest<NSFetchRequestResult> = CardTemplate.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("✅ 所有卡片模板已重置")
        } catch {
            print("❌ 重置模板失败: \(error)")
        }
    }
    
    // 添加自定义模板
    func addCustomTemplate(series: AnimeSeries, 
                          character: String, 
                          rarity: Rarity, 
                          context: NSManagedObjectContext) -> Bool {
        // 检查是否已存在
        let request: NSFetchRequest<CardTemplate> = CardTemplate.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "animeSeries == %@", series.rawValue),
            NSPredicate(format: "characterName == %@", character),
            NSPredicate(format: "rarity == %d", rarity.weight)
        ])
        
        do {
            let existing = try context.fetch(request)
            if !existing.isEmpty {
                print("⚠️ 模板已存在: \(series.rawValue) - \(character) [\(rarity.displayName)]")
                return false
            }
            
            // 创建新模板
            createTemplate(series: series, character: character, rarity: rarity, context: context)
            try context.save()
            print("✅ 添加模板成功: \(series.rawValue) - \(character) [\(rarity.displayName)]")
            return true
        } catch {
            print("❌ 添加模板失败: \(error)")
            return false
        }
    }
}
