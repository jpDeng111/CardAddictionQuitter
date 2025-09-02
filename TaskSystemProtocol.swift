protocol MissionSystem {
    func completeMission(type: MissionType)
    func getProbabilityBoost() -> Double
}

enum MissionType {
    case noFapDiary
    case goodDeedRecord
    // 后续可扩展任务类型
}