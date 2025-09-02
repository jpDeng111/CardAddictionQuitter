struct GachaMachine {
    let baseRate: [Rarity: Double] = [
        .SSR: 0.01,
        .SR: 0.09,
        .R: 0.30,
        .N: 0.60
    ]
    
    func draw() -> Card {
        let rand = Double.random(in: 0...1)
        var current: Double = 0
        // 分级概率计算逻辑
        // ... existing code ...
    }
}