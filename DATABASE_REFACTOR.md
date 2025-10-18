# 数据库重构文档

## 重构概述

本次重构解决了原有数据库设计的核心问题：**将卡片模板(CardTemplate)和用户拥有的卡片(UserCard)分离**，实现了更合理的数据架构。

## 重构动机

### 原有问题
1. **数据冗余**：同一角色的卡片属性在每个用户的Card记录中重复存储
2. **难以管理**：无法统一更新卡片属性，缺少卡片图鉴功能
3. **扩展性差**：添加新卡片需要为每个用户创建记录

### 解决方案
采用**模板-实例分离**设计模式：
- `CardTemplate`：存储所有可能的卡片类型和属性（共享数据）
- `UserCard`：存储用户实际拥有的卡片实例（个人数据）

---

## 新数据库架构

### 📊 实体关系图

```
User (用户)
  │
  ├─── 1:N ──→ UserCard (用户卡片)
  │               │
  │               └─── N:1 ──→ CardTemplate (卡片模板)
  │
  ├─── 1:N ──→ MissionRecord (任务记录)
  │
  ├─── 1:N ──→ DrawRecord (抽卡记录)
  │               │
  │               └─── N:1 ──→ UserCard
  │
  └─── 1:N ──→ UsageRecord (使用记录)
```

### 📋 实体详细设计

#### 1. User (用户表)
```
id: UUID              - 主键
username: String      - 用户名
totalDrawCount: Int32 - 总抽卡次数
createdDate: Date     - 注册时间
lastLoginDate: Date   - 最后登录时间
```

#### 2. CardTemplate (卡片模板表) ⭐新增
```
id: UUID              - 主键
animeSeries: String   - 动漫系列
characterName: String - 角色名称
rarity: Int16         - 稀有度 (1=N, 2=R, 3=SR, 4=SSR)
attackBonus: Int32    - 攻击加成
defenseBonus: Int32   - 防御加成
cardDescription: String - 卡片描述
imageUrl: String      - 卡片图片URL
isActive: Bool        - 是否启用
```

**特点**：
- 所有用户共享，只需初始化一次
- 支持动态启用/禁用卡片
- 便于批量更新卡片属性

#### 3. UserCard (用户卡片表) ⭐新增
```
id: UUID              - 主键
userId: UUID          - 外键 → User.id
templateId: UUID      - 外键 → CardTemplate.id
obtainDate: Date      - 获得时间
isBoosted: Bool       - 是否使用概率提升
level: Int16          - 卡片等级
experience: Int32     - 经验值
isFavorite: Bool      - 是否收藏
```

**特点**：
- 关联模板获取卡片基础属性
- 支持卡片升级系统
- 个性化数据（等级、经验、收藏）

#### 4. MissionRecord (任务记录表)
```
id: UUID              - 主键
userId: UUID          - 外键 → User.id
type: String          - 任务类型
completedDate: Date   - 完成时间
probabilityBoost: Double - 概率提升值
```

#### 5. DrawRecord (抽卡记录表)
```
id: UUID              - 主键
userId: UUID          - 外键 → User.id
userCardId: UUID      - 外键 → UserCard.id (从cardId改为userCardId)
timestamp: Date       - 抽卡时间
drawType: String      - 抽卡类型 (single/multi) ⭐新增
```

#### 6. UsageRecord (使用记录表)
```
id: UUID              - 主键
userId: UUID          - 外键 → User.id
date: Date            - 使用日期
duration: Double      - 使用时长(秒)
```

---

## 重构内容清单

### ✅ 新增文件

1. **CardTemplate+CoreDataClass.swift**
   - 卡片模板核心类
   - 属性计算和转换方法
   - 稀有度判断逻辑

2. **CardTemplate+CoreDataProperties.swift**
   - 查询谓词（按稀有度、系列、角色）
   - 排序描述符
   - 统计分析方法
   - 随机获取模板

3. **UserCard+CoreDataClass.swift**
   - 用户卡片核心类
   - 等级和经验系统
   - 获取关联模板
   - 属性计算（含等级加成）

4. **UserCard+CoreDataProperties.swift**
   - 丰富的查询方法
   - 收藏管理
   - 统计分析
   - 模板所有权检查

5. **GachaSystemV2.swift**
   - 新版抽卡系统
   - 适配CardTemplate和UserCard
   - 保底机制优化
   - 抽卡统计功能

6. **CardTemplateInitializer.swift**
   - 卡片模板初始化器
   - 自动生成所有卡片模板
   - 模板管理和统计
   - 支持自定义模板

7. **RefactoredDatabaseTest.swift**
   - 完整的测试套件
   - 7个测试场景
   - 升级系统测试

### 📝 修改文件

1. **DataModel.xcdatamodeld**
   - 添加CardTemplate实体
   - 添加UserCard实体
   - 更新DrawRecord字段（cardId→userCardId，新增drawType）
   - 为所有实体添加userId外键

2. **DrawRecord+CoreDataClass.swift**
   - 更新字段名：cardId → userCardId
   - 添加drawType字段
   - 添加getUserCard()方法
   - 添加DrawType枚举

3. **DrawRecord+CoreDataProperties.swift**
   - 更新属性定义

4. **TimeExchangeLogic.swift**
   - 所有方法添加userId参数
   - 更新查询条件包含userId过滤

---

## 核心功能实现

### 🎮 抽卡流程

```swift
// 1. 确定稀有度
let rarity = determineRarity()

// 2. 获取对应稀有度的随机模板
let template = CardTemplate.randomTemplate(rarity: rarity, context: context)

// 3. 创建用户卡片实例
let userCard = UserCard(context: context, 
                        userId: userId, 
                        templateId: template.id!)

// 4. 记录抽卡
let drawRecord = DrawRecord(context: context,
                            userCardId: userCard.id!,
                            userId: userId)
```

### 📈 卡片升级系统

```swift
// 添加经验
let didLevelUp = userCard.addExperience(150, context: context)

// 自动升级计算
while experience >= experienceNeeded && level < 100 {
    experience -= experienceNeeded
    level += 1
}

// 属性随等级增长
攻击 = 基础攻击 + (等级-1) × 6
防御 = 基础防御 + (等级-1) × 4
```

### 📊 统计分析

```swift
// 用户卡片统计
UserCard.countUserCards(userId: userId, context: context)
UserCard.countByRarity(userId: userId, context: context)
UserCard.averageLevel(userId: userId, context: context)

// 模板统计
CardTemplate.countByRarity(context: context)
CardTemplate.countByAnimeSeries(context: context)

// 抽卡统计
gachaSystem.getDrawStatistics(userId: userId, context: context)
```

---

## 使用指南

### 1. 初始化卡片模板

```swift
let context = PersistenceController.shared.container.viewContext
CardTemplateInitializer.shared.initializeTemplates(context: context)
```

### 2. 执行抽卡

```swift
// 单抽
let card = GachaSystemV2.shared.draw(userId: userId, context: context)

// 10连抽
let cards = GachaSystemV2.shared.drawMultiple(userId: userId, 
                                               count: 10, 
                                               context: context)
```

### 3. 查询用户卡片

```swift
// 获取所有卡片
let request: NSFetchRequest<UserCard> = UserCard.fetchRequest()
request.predicate = UserCard.predicateForUser(userId: userId)
let cards = try context.fetch(request)

// 获取收藏卡片
request.predicate = UserCard.predicateForUserFavorites(userId: userId)
```

### 4. 运行测试

```swift
let tester = RefactoredDatabaseTest.shared
tester.runFullTest()
tester.testCardLevelUp(context: context)
```

---

## 优势对比

| 特性 | 旧架构 | 新架构 |
|------|--------|--------|
| 数据冗余 | ❌ 每个用户重复存储 | ✅ 模板共享 |
| 卡片更新 | ❌ 需要更新所有用户记录 | ✅ 只需更新模板 |
| 升级系统 | ❌ 不支持 | ✅ 完整支持 |
| 图鉴功能 | ❌ 难以实现 | ✅ 直接查询模板 |
| 存储空间 | ❌ 随用户增长 | ✅ 模板固定 |
| 查询效率 | ⚠️ 一般 | ✅ 更高 |
| 扩展性 | ❌ 差 | ✅ 优秀 |

---

## 迁移建议

### 从旧版本迁移

如果已有旧版本数据，需要：

1. **导出现有数据**
```swift
// 导出旧Card数据
let oldCards = try context.fetch(Card.fetchRequest())
```

2. **创建模板**
```swift
// 为每种独特的卡片创建模板
CardTemplateInitializer.shared.initializeTemplates(context: context)
```

3. **迁移用户卡片**
```swift
for oldCard in oldCards {
    // 找到对应模板
    let template = findMatchingTemplate(oldCard)
    
    // 创建新UserCard
    let userCard = UserCard(context: context,
                           userId: oldCard.userId,
                           templateId: template.id!)
    userCard.obtainDate = oldCard.obtainDate
    userCard.isBoosted = oldCard.isBoosted
}
```

4. **删除旧数据**
```swift
// 验证迁移成功后删除
```

---

## 性能优化建议

1. **索引优化**
   - 在userId字段创建索引
   - 在templateId字段创建索引
   - 在completedDate/timestamp字段创建索引

2. **批量操作**
   - 10连抽使用单次save
   - 批量查询使用fetchLimit

3. **缓存策略**
   - 缓存CardTemplate（不常变化）
   - 用户卡片数据按需加载

---

## 未来扩展

### 可能的功能扩展

1. **卡片合成系统**
   - 多张低级卡片合成高级卡片
   - UserCard表已预留level和experience字段

2. **卡片技能系统**
   - 在CardTemplate添加skills字段
   - 每个稀有度对应不同技能

3. **交易系统**
   - 添加CardTrade表
   - 记录用户间卡片交易

4. **成就系统**
   - 收集特定组合卡片获得成就
   - 基于UserCard查询实现

---

## 总结

本次重构采用了**模板-实例分离**的经典设计模式，显著提升了：
- ✅ 数据一致性
- ✅ 存储效率
- ✅ 查询性能
- ✅ 系统扩展性
- ✅ 代码可维护性

数据库架构现已完全适配项目需求，为后续功能开发奠定了坚实基础。
