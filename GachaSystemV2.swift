import Foundation
import CoreData

// 新版抽卡系统 - 使用CardTemplate和UserCard
class GachaSystemV2 {
    // 单例模式
    static let shared = GachaSystemV2()
    private init() {}
    
    // 基础概率配置
    let baseRate: [Rarity: Double] = [
        .SSR: 0.01,  // 1%
        .SR: 0.09,   // 9%
        .R: 0.30,    // 30%
        .N: 0.60     // 60%
    ]
    
    // 保底机制计数器
    private let pityThreshold = 100  // 每100抽必出SSR
    private let srPityThreshold = 10 // 每10抽必出SR或更高
    
    // 执行单次抽卡操作
    func draw(userId: UUID, context: NSManagedObjectContext) -> UserCard? {
        // 从任务系统获取当前的概率提升值
        let probabilityBoost = DefaultMissionSystem.shared.getProbabilityBoost()
        
        // 确定稀有度
        let rarity: Rarity
        if probabilityBoost > 0 {
            rarity = determineRarityWithBoost(boost: probabilityBoost)
        } else {
            rarity = determineRarity()
        }
        
        // 获取对应稀有度的随机模板
        guard let template = CardTemplate.randomTemplate(rarity: rarity, context: context) else {
            print("Error: No template found for rarity \(rarity)")
            return nil
        }
        
        // 创建用户卡片
        let userCard = UserCard(context: context,
                                userId: userId,
                                templateId: template.id!,
                                isBoosted: probabilityBoost > 0)
        
        // 记录抽卡
        let drawRecord = DrawRecord(context: context,
                                   userCardId: userCard.id!,
                                   userId: userId,
                                   drawType: .single)
        
        // 保存
        do {
            try context.save()
            return userCard
        } catch {
            print("Error saving draw: \(error)")
            return nil
        }
    }
    
    // 执行10连抽
    func drawMultiple(userId: UUID, count: Int = 10, context: NSManagedObjectContext) -> [UserCard] {
        var drawnCards: [UserCard] = []
        
        let probabilityBoost = DefaultMissionSystem.shared.getProbabilityBoost()
        
        for i in 0..<count {
            var rarity: Rarity
            
            // 10连抽最后一张保底SR或更高
            if count >= 10 && i == count - 1 {
                // 检查前9张是否有SR或更高
                let hasHighRarity = drawnCards.contains { card in
                    card.getRarity(context: context).weight >= Rarity.SR.weight
                }
                
                if !hasHighRarity {
                    // 保底SR，有小概率出SSR
                    rarity = Double.random(in: 0...1) < 0.1 ? .SSR : .SR
                } else {
                    // 正常抽卡
                    rarity = probabilityBoost > 0 ? 
                        determineRarityWithBoost(boost: probabilityBoost) : 
                        determineRarity()
                }
            } else {
                // 正常抽卡
                rarity = probabilityBoost > 0 ? 
                    determineRarityWithBoost(boost: probabilityBoost) : 
                    determineRarity()
            }
            
            // 获取模板并创建用户卡片
            if let template = CardTemplate.randomTemplate(rarity: rarity, context: context) {
                let userCard = UserCard(context: context,
                                       userId: userId,
                                       templateId: template.id!,
                                       isBoosted: probabilityBoost > 0)
                drawnCards.append(userCard)
                
                // 记录抽卡
                _ = DrawRecord(context: context,
                             userCardId: userCard.id!,
                             userId: userId,
                             drawType: .multi)
            }
        }
        
        // 保存所有卡片
        do {
            try context.save()
        } catch {
            print("Error saving multiple draws: \(error)")
        }
        
        // 按稀有度排序返回
        return drawnCards.sorted { 
            $0.getRarity(context: context).weight > $1.getRarity(context: context).weight 
        }
    }
    
    // 确定稀有度（基础概率）
    private func determineRarity() -> Rarity {
        let rand = Double.random(in: 0...1)
        var current: Double = 0
        
        // 按稀有度降序遍历以确保正确计算
        let sortedRates = baseRate.sorted { $0.key.weight > $1.key.weight }
        
        for (rarity, rate) in sortedRates {
            current += rate
            if rand <= current {
                return rarity
            }
        }
        
        return .N
    }
    
    // 确定稀有度（概率提升）
    private func determineRarityWithBoost(boost: Double) -> Rarity {
        // 计算提升后的概率
        let ssrRate = min(baseRate[.SSR]! * (1 + boost), 0.5)
        let srRate = min(baseRate[.SR]! * (1 + boost * 0.5), 0.5)
        let rRate = baseRate[.R]!
        let nRate = max(0, 1 - (ssrRate + srRate + rRate))
        
        let boostedRates: [Rarity: Double] = [
            .SSR: ssrRate,
            .SR: srRate,
            .R: rRate,
            .N: nRate
        ]
        
        let rand = Double.random(in: 0...1)
        var current: Double = 0
        
        for (rarity, rate) in boostedRates.sorted(by: { $0.key.weight > $1.key.weight }) {
            current += rate
            if rand <= current {
                return rarity
            }
        }
        
        return .N
    }
    
    // 获取用户的保底状态
    func getPityStatus(userId: UUID, context: NSManagedObjectContext) -> (current: Int, srCurrent: Int) {
        let request: NSFetchRequest<DrawRecord> = DrawRecord.fetchRequest()
        request.predicate = DrawRecord.predicateForUser(userId: userId)
        request.sortDescriptors = DrawRecord.sortByTimestampDescending
        
        do {
            let records = try context.fetch(request)
            
            // 计算距离上次SSR的抽数
            var ssrCounter = 0
            var srCounter = 0
            
            for record in records {
                if let userCard = record.getUserCard(context: context) {
                    let rarity = userCard.getRarity(context: context)
                    
                    if rarity == .SSR {
                        break
                    }
                    ssrCounter += 1
                    
                    if srCounter < srPityThreshold {
                        if rarity.weight >= Rarity.SR.weight {
                            srCounter = 0
                        } else {
                            srCounter += 1
                        }
                    }
                }
            }
            
            return (current: ssrCounter, srCurrent: srCounter)
        } catch {
            print("Error getting pity status: \(error)")
            return (current: 0, srCurrent: 0)
        }
    }
    
    // 获取当前概率配置的描述
    func getProbabilityDescription() -> String {
        var description = "当前抽卡概率：\n"
        description += "SSR: \(String(format: "%.2f", baseRate[.SSR]! * 100))%\n"
        description += "SR: \(String(format: "%.2f", baseRate[.SR]! * 100))%\n"
        description += "R: \(String(format: "%.2f", baseRate[.R]! * 100))%\n"
        description += "N: \(String(format: "%.2f", baseRate[.N]! * 100))%\n"
        
        description += "\n保底机制：\n"
        description += "每\(srPityThreshold)抽必出SR或更高品质\n"
        description += "每\(pityThreshold)抽必出SSR品质"
        
        return description
    }
    
    // 获取用户抽卡统计
    func getDrawStatistics(userId: UUID, context: NSManagedObjectContext) -> DrawStatistics {
        let totalDraws = DrawRecord.countForUser(userId: userId, context: context)
        let rarityCounts = UserCard.countByRarity(userId: userId, context: context)
        
        return DrawStatistics(
            totalDraws: totalDraws,
            nCount: rarityCounts[.N] ?? 0,
            rCount: rarityCounts[.R] ?? 0,
            srCount: rarityCounts[.SR] ?? 0,
            ssrCount: rarityCounts[.SSR] ?? 0
        )
    }
}

// 抽卡统计结构
struct DrawStatistics {
    let totalDraws: Int
    let nCount: Int
    let rCount: Int
    let srCount: Int
    let ssrCount: Int
    
    var ssrRate: Double {
        guard totalDraws > 0 else { return 0 }
        return Double(ssrCount) / Double(totalDraws) * 100
    }
    
    var srRate: Double {
        guard totalDraws > 0 else { return 0 }
        return Double(srCount) / Double(totalDraws) * 100
    }
    
    var description: String {
        return """
        总抽卡次数：\(totalDraws)
        N卡：\(nCount)
        R卡：\(rCount)
        SR卡：\(srCount) (出率: \(String(format: "%.2f", srRate))%)
        SSR卡：\(ssrCount) (出率: \(String(format: "%.2f", ssrRate))%)
        """
    }
}

// 扩展DrawRecord添加统计方法
extension DrawRecord {
    static func countForUser(userId: UUID, context: NSManagedObjectContext) -> Int {
        let request: NSFetchRequest<DrawRecord> = DrawRecord.fetchRequest()
        request.predicate = predicateForUser(userId: userId)
        
        do {
            return try context.count(for: request)
        } catch {
            print("Error counting draws: \(error)")
            return 0
        }
    }
}
