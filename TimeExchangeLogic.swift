func calculateDrawChances(usageHours: Double) -> Int {
    let baseChance = 5
    let penalty = max(0, Int(usageHours) - 3)
    return max(0, baseChance - penalty)
}