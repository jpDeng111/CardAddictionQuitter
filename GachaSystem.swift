import Foundation

// 稀有度枚举
enum Rarity: String, CaseIterable {
    case N = "N"
    case R = "R"
    case SR = "SR"
    case SSR = "SSR"
    
    // 稀有度对应的颜色和名称
    var displayColor: String {
        switch self {
        case .N: return "#888888"
        case .R: return "#008000"
        case .SR: return "#0000FF"
        case .SSR: return "#FF00FF"
        }
    }
    
    var displayName: String {
        switch self {
        case .N: return "普通"
        case .R: return "稀有"
        case .SR: return "超稀有"
        case .SSR: return "最稀有"
        }
    }
    
    // 稀有度对应的权重（用于排序）
    var weight: Int {
        switch self {
        case .N: return 1
        case .R: return 2
        case .SR: return 3
        case .SSR: return 4
        }
    }
}

// 动漫IP枚举
enum AnimeSeries: String, CaseIterable {
    case onePiece = "海贼王"
    case naruto = "火影忍者"
    case demonSlayer = "鬼灭之刃"
    case frieren = "葬送的芙莉莲"
    
    // 每个动漫IP的角色池
    var characters: [String] {
        switch self {
        case .onePiece:
            return ["路飞", "索隆", "娜美", "山治", "乌索普", "乔巴", "罗宾", "弗兰奇", "布鲁克"]
        case .naruto:
            return ["鸣人", "佐助", "小樱", "卡卡西", "我爱罗", "纲手", "自来也", "大蛇丸"]
        case .demonSlayer:
            return ["炭治郎", "祢豆子", "我妻善逸", "嘴平伊之助", "富冈义勇", "蝴蝶忍", "炼狱杏寿郎"]
        case .frieren:
            return ["芙莉莲", "费伦", "艾森", "哈忒", "希丝缇娜", "乌里", "拉赫特"]
        }
    }
    
    // 动漫IP的图标（未来可扩展）
    var iconName: String {
        switch self {
        case .onePiece: return "onepiece_icon"
        case .naruto: return "naruto_icon"
        case .demonSlayer: return "demonslayer_icon"
        case .frieren: return "frieren_icon"
        }
    }
}

// 卡片结构体
struct Card: Identifiable, Codable {
    let id: UUID
    let animeSeries: AnimeSeries
    let characterName: String
    let rarity: Rarity
    let obtainDate: Date
    let isBoosted: Bool // 是否使用了概率提升
    
    // 稀有度对应的卡牌属性加成
    var attackBonus: Int {
        switch rarity {
        case .N: return 10
        case .R: return 30
        case .SR: return 60
        case .SSR: return 100
        }
    }
    
    var defenseBonus: Int {
        switch rarity {
        case .N: return 5
        case .R: return 15
        case .SR: return 30
        case .SSR: return 50
        }
    }
    
    // 卡牌总属性值
    var totalStats: Int {
        return attackBonus + defenseBonus
    }
    
    // 卡牌描述
    var cardDescription: String {
        return "\(characterName) - \(animeSeries.rawValue)\n稀有度：\(rarity.displayName)\n攻击：+\(attackBonus) 防御：+\(defenseBonus)"
    }
}

// 抽卡系统结构体
struct GachaSystem {
    // 基础概率配置
    let baseRate: [Rarity: Double] = [
        .SSR: 0.01,  // 1%
        .SR: 0.09,   // 9%
        .R: 0.30,    // 30%
        .N: 0.60     // 60%
    ]
    
    // 保底机制计数器
    private var pityCounter = 0
    private let pityThreshold = 100  // 每100抽必出SSR
    private let srPityThreshold = 10 // 每10抽必出SR或更高
    
    // 执行抽卡操作
    func draw() -> Card {
        // 从任务系统获取当前的概率提升值
        let probabilityBoost = DefaultMissionSystem.shared.getProbabilityBoost()
        
        // 如果有概率提升，使用提升后的概率抽卡
        if probabilityBoost > 0 {
            return drawWithProbabilityBoost(boost: probabilityBoost)
        }
        
        let rand = Double.random(in: 0...1)
        var current: Double = 0
        
        // 分级概率计算逻辑
        for (rarity, rate) in baseRate {
            current += rate
            if rand <= current {
                return generateCard(with: rarity, isBoosted: false)
            }
        }
        
        // 兜底返回N级卡牌
        return generateCard(with: .N, isBoosted: false)
    }
    
    // 多抽机制（10连抽）
    func drawMultiple(count: Int) -> [Card] {
        var cards: [Card] = []
        
        // 从任务系统获取当前的概率提升值
        let probabilityBoost = DefaultMissionSystem.shared.getProbabilityBoost()
        let shouldUseBoost = probabilityBoost > 0
        
        for i in 0..<count {
            // 10连抽必有一张SR或更高
            if count >= 10 && i == count - 1 {
                let guaranteedRarity: Rarity = Bool.random() ? .SSR : .SR
                cards.append(generateCard(with: guaranteedRarity, isBoosted: false))
                continue
            }
            
            // 使用概率提升抽卡
            if shouldUseBoost {
                let boostedCard = drawWithProbabilityBoost(boost: probabilityBoost)
                cards.append(boostedCard)
            } else {
                // 普通抽卡逻辑
                let card = draw()
                cards.append(card)
            }
        }
        
        // 按稀有度排序（SSR > SR > R > N）
        return cards.sorted { $0.rarity.weight > $1.rarity.weight }
    }
    
    // 根据稀有度生成卡牌
    private func generateCard(with rarity: Rarity, isBoosted: Bool) -> Card {
        let animeSeries = AnimeSeries.allCases.randomElement()!
        let characterName = animeSeries.characters.randomElement()!
        
        return Card(
            id: UUID(),
            animeSeries: animeSeries,
            characterName: characterName,
            rarity: rarity,
            obtainDate: Date(),
            isBoosted: isBoosted
        )
    }
    
    // 任务奖励概率提升抽卡
    func drawWithProbabilityBoost(boost: Double) -> Card {
        // 计算提升后的概率，SSR提升更多
        let ssrRate = min(baseRate[.SSR]! * (1 + boost), 0.5)  // SSR概率最多提升到50%
        let srRate = min(baseRate[.SR]! * (1 + boost * 0.5), 0.5) // SR概率提升稍低
        let rRate = baseRate[.R]!
        
        // 确保概率总和为1
        let nRate = max(0, 1 - (ssrRate + srRate + rRate))
        
        let boostedRates: [Rarity: Double] = [
            .SSR: ssrRate,
            .SR: srRate,
            .R: rRate,
            .N: nRate
        ]
        
        let rand = Double.random(in: 0...1)
        var current: Double = 0
        
        for (rarity, rate) in boostedRates {
            current += rate
            if rand <= current {
                return generateCard(with: rarity, isBoosted: true)
            }
        }
        
        // 兜底返回N级卡牌
        return generateCard(with: .N, isBoosted: true)
    }
    
    // 检查保底状态
    func getPityStatus() -> (current: Int, threshold: Int, srCurrent: Int, srThreshold: Int) {
        return (pityCounter, pityThreshold, pityCounter % srPityThreshold, srPityThreshold)
    }
    
    // 重置保底计数器
    mutating func resetPityCounter() {
        pityCounter = 0
    }
    
    // 增加保底计数器
    mutating func incrementPityCounter() {
        pityCounter += 1
    }
    
    // 获取当前概率配置的描述
    func getProbabilityDescription() -> String {
        var description = "当前抽卡概率：\n"
        description += "SSR: \(String(format: "%.2f", baseRate[.SSR]! * 100))%\n"
        description += "SR: \(String(format: "%.2f", baseRate[.SR]! * 100))%\n"
        description += "R: \(String(format: "%.2f", baseRate[.R]! * 100))%\n"
        description += "N: \(String(format: "%.2f", baseRate[.N]! * 100))%\n"
        
        // 添加保底机制说明
        description += "\n保底机制：\n"
        description += "每\(srPityThreshold)抽必出SR或更高品质\n"
        description += "每\(pityThreshold)抽必出SSR品质"
        
        return description
    }
}