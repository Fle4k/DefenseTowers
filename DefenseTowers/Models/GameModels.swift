//
//  GameModels.swift
//  DefenseTowers
//
//  Core game models for tower defense game
//

import SwiftUI
import Combine
import UIKit

// MARK: - Game State Enum
enum GameStateType {
    case notStarted
    case playing
    case paused
    case gameOver
}

// MARK: - Core Game State
class GameState: ObservableObject {
    @Published var coins: Int = 100
    @Published var health: Int = 20
    @Published var currentWave: Int = 0
    @Published var enemies: [Enemy] = []
    @Published var towers: [Tower] = []
    @Published var projectiles: [Projectile] = []
    @Published var blasts: [AoEBlast] = []
    @Published var gameOver: Bool = false
    @Published var score: Int = 0
    @Published var enemiesEscaped: Int = 0
    @Published var gameState: GameStateType = .notStarted
    @Published var showPauseOverlay: Bool = false
    @Published var selectedTower: Tower? = nil
    
    var waveManager: WaveManager!
    var timer: AnyCancellable?
    
    init() {
        waveManager = WaveManager(gameState: self)
    }
    
    func startGameLoop() {
        gameState = .playing
        timer = Timer.publish(every: 0.016, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.update()
            }
    }
    
    func stopGameLoop() {
        timer?.cancel()
    }
    
    func resetGame() {
        stopGameLoop()
        coins = 100
        health = 20
        currentWave = 0
        enemies.removeAll()
        towers.removeAll()
        projectiles.removeAll()
        blasts.removeAll()
        gameOver = false
        score = 0
        enemiesEscaped = 0
        gameState = .notStarted
        showPauseOverlay = false
        selectedTower = nil
        waveManager = WaveManager(gameState: self)
    }
    
    func pauseGame() {
        gameState = .paused
        showPauseOverlay = true
        timer?.cancel()
        waveManager.stopCurrentWave()
    }
    
    func resumeGame() {
        gameState = .playing
        showPauseOverlay = false
        startGameLoop()
    }
    
    func handleAppDidEnterBackground() {
        if !gameOver && gameState == .playing {
            pauseGame()
        }
    }
    
    private func triggerHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func update() {
        guard !gameOver && gameState == .playing else { return }
        
        // Move enemies
        for i in enemies.indices.reversed() {
            enemies[i].move()
            if enemies[i].reachedGoal {
                health -= enemies[i].type.damage
                enemiesEscaped += 1
                enemies[i].isAlive = false
                triggerHapticFeedback()
                if health <= 0 {
                    gameOver = true
                    gameState = .gameOver
                }
            }
        }
        
        // Towers fire
        for tower in towers {
            tower.update(gameState: self)
        }
        
        // Projectiles update
        for i in projectiles.indices.reversed() {
            projectiles[i].update(gameState: self)
        }
        
        // Remove expired blasts
        let now = CACurrentMediaTime()
        blasts.removeAll { now - $0.createdAt > 0.3 }
        
        // Cleanup dead objects
        enemies.removeAll { !$0.isAlive }
        projectiles.removeAll { !$0.isAlive }
    }
}

// MARK: - Enemy Types
enum EnemyType: CaseIterable {
    case basic, fast, tank, swarm, boss
    
    var displayName: String {
        switch self {
        case .basic: return "Basic"
        case .fast: return "Fast"
        case .tank: return "Tank"
        case .swarm: return "Swarm"
        case .boss: return "Boss"
        }
    }
    
    var maxHealth: Int {
        switch self {
        case .basic: return 50
        case .fast: return 30
        case .tank: return 150
        case .swarm: return 20
        case .boss: return 300
        }
    }
    
    var speed: CGFloat {
        switch self {
        case .basic: return 1.0
        case .fast: return 2.5
        case .tank: return 0.6
        case .swarm: return 1.8
        case .boss: return 0.8
        }
    }
    
    var reward: Int {
        switch self {
        case .basic: return 10
        case .fast: return 8
        case .tank: return 25
        case .swarm: return 5
        case .boss: return 50
        }
    }
    
    var damage: Int {
        switch self {
        case .basic: return 1
        case .fast: return 1
        case .tank: return 2
        case .swarm: return 1
        case .boss: return 3
        }
    }
    
    var color: Color {
        switch self {
        case .basic: return .red
        case .fast: return .yellow
        case .tank: return .purple
        case .swarm: return .orange
        case .boss: return .black
        }
    }
    
    var size: CGFloat {
        switch self {
        case .basic: return 18
        case .fast: return 14
        case .tank: return 26
        case .swarm: return 12
        case .boss: return 35
        }
    }
}

// MARK: - Enemy
struct Enemy: Identifiable {
    let id = UUID()
    var type: EnemyType
    var health: Int
    var maxHealth: Int
    var speed: CGFloat
    var position: CGPoint
    var path: [CGPoint]
    var currentWaypoint: Int = 0
    var isAlive: Bool = true
    
    var reachedGoal: Bool {
        return currentWaypoint >= path.count
    }
    
    var healthPercentage: Double {
        return Double(health) / Double(maxHealth)
    }
    
    init(type: EnemyType, position: CGPoint, path: [CGPoint], waveMultiplier: Double = 1.0) {
        self.type = type
        let baseHealth = Int(Double(type.maxHealth) * waveMultiplier)
        self.health = baseHealth
        self.maxHealth = baseHealth
        self.speed = type.speed
        self.position = position
        self.path = path
    }
    
    mutating func move() {
        guard isAlive, !reachedGoal else { return }
        let target = path[currentWaypoint]
        let dx = target.x - position.x
        let dy = target.y - position.y
        let dist = sqrt(dx*dx + dy*dy)
        
        if dist < speed {
            position = target
            currentWaypoint += 1
        } else {
            position.x += dx / dist * speed
            position.y += dy / dist * speed
        }
    }
}

// MARK: - Tower Types
enum TowerType: CaseIterable {
    case peace, tree, wave, sun, moon
    
    var displayName: String {
        switch self {
        case .peace: return "Peace"
        case .tree: return "Tree"
        case .wave: return "Wave"
        case .sun: return "Sun"
        case .moon: return "Moon"
        }
    }
    
    var cost: Int {
        switch self {
        case .peace: return 50
        case .tree: return 80
        case .wave: return 100
        case .sun: return 120
        case .moon: return 150
        }
    }
    
    var range: CGFloat {
        switch self {
        case .peace: return 80
        case .tree: return 70
        case .wave: return 90
        case .sun: return 140
        case .moon: return 60
        }
    }
    
    var damage: Int {
        switch self {
        case .peace: return 15
        case .tree: return 12
        case .wave: return 18
        case .sun: return 35
        case .moon: return 25
        }
    }
    
    var fireRate: TimeInterval {
        switch self {
        case .peace: return 0.6
        case .tree: return 0.4
        case .wave: return 0.8
        case .sun: return 1.2
        case .moon: return 0.5
        }
    }
    
    var color: Color {
        switch self {
        case .peace: return .blue
        case .tree: return .green
        case .wave: return .cyan
        case .sun: return .yellow
        case .moon: return .purple
        }
    }
    
    var projectileSpeed: CGFloat {
        switch self {
        case .peace: return 6
        case .tree: return 5
        case .wave: return 7
        case .sun: return 10
        case .moon: return 8
        }
    }
}

// MARK: - Tower
class Tower: Identifiable, ObservableObject {
    let id = UUID()
    var type: TowerType
    var position: CGPoint
    var range: CGFloat
    var damage: Int
    var fireRate: TimeInterval
    private var lastFireTime: TimeInterval = 0
    
    // Upgrade properties
    @Published var canPierce: Bool = false
    @Published var hasExtremeRange: Bool = false
    @Published var hasFastFire: Bool = false
    
    init(type: TowerType, position: CGPoint) {
        self.type = type
        self.position = position
        self.range = type.range
        self.damage = type.damage
        self.fireRate = type.fireRate
    }
    
    func update(gameState: GameState) {
        let now = CACurrentMediaTime()
        let currentFireRate = hasFastFire ? fireRate * 0.5 : fireRate
        guard now - lastFireTime > currentFireRate else { return }
        
        switch type {
        case .moon:
            // Moon tower damages all enemies in range (AoE)
            var hitAny = false
            for i in gameState.enemies.indices {
                let enemy = gameState.enemies[i]
                let dx = enemy.position.x - position.x
                let dy = enemy.position.y - position.y
                let dist = sqrt(dx*dx + dy*dy)
                
                if dist <= range && gameState.enemies[i].isAlive {
                    gameState.enemies[i].health -= damage
                    if gameState.enemies[i].health <= 0 {
                        gameState.enemies[i].isAlive = false
                        gameState.coins += enemy.type.reward
                        gameState.score += enemy.type.reward * 2
                    }
                    hitAny = true
                }
            }
            
            if hitAny {
                gameState.blasts.append(AoEBlast(position: position, radius: range, createdAt: now))
                lastFireTime = now
            }
            
        default:
            // Find closest enemy in range
            let enemiesInRange = gameState.enemies.filter { enemy in
                let dx = enemy.position.x - position.x
                let dy = enemy.position.y - position.y
                let dist = sqrt(dx*dx + dy*dy)
                return dist <= range && enemy.isAlive
            }
            
            // Target the enemy furthest along the path
            if let target = enemiesInRange.max(by: { $0.currentWaypoint < $1.currentWaypoint }) {
                let projectile = Projectile(
                    origin: position,
                    targetId: target.id,
                    speed: type.projectileSpeed,
                    damage: damage,
                    pierces: canPierce && type == .sun,
                    towerType: type
                )
                gameState.projectiles.append(projectile)
                lastFireTime = now
            }
        }
    }
    
    func getUpgradeCost(upgrade: UpgradeType) -> Int {
        switch upgrade {
        case .pierce: return 80
        case .range: return 60
        case .fastFire: return 70
        }
    }
    
    func canUpgrade(_ upgrade: UpgradeType) -> Bool {
        switch upgrade {
        case .pierce: return type == .sun && !canPierce
        case .range: return !hasExtremeRange
        case .fastFire: return type == .tree && !hasFastFire
        }
    }
    
    func applyUpgrade(_ upgrade: UpgradeType) {
        switch upgrade {
        case .pierce:
            canPierce = true
        case .range:
            hasExtremeRange = true
            range *= 1.4
        case .fastFire:
            hasFastFire = true
        }
    }
}

enum UpgradeType {
    case pierce, range, fastFire
    
    var displayName: String {
        switch self {
        case .pierce: return "🔫 Pierce"
        case .range: return "🎯 Range"
        case .fastFire: return "⚡ Fast Fire"
        }
    }
}

// MARK: - Projectile
struct Projectile: Identifiable {
    let id = UUID()
    var origin: CGPoint
    var position: CGPoint
    var targetId: UUID
    var speed: CGFloat
    var damage: Int
    var isAlive: Bool = true
    var pierces: Bool = false
    var towerType: TowerType
    private var enemiesHit: Set<UUID> = []
    
    init(origin: CGPoint, targetId: UUID, speed: CGFloat, damage: Int, pierces: Bool = false, towerType: TowerType) {
        self.origin = origin
        self.position = origin
        self.targetId = targetId
        self.speed = speed
        self.damage = damage
        self.pierces = pierces
        self.towerType = towerType
    }
    
    mutating func update(gameState: GameState) {
        // Find target or any enemy if piercing
        var targetEnemy: Enemy?
        var targetIndex: Int = -1
        
        if pierces {
            // For piercing projectiles, find any enemy in path
            for (index, enemy) in gameState.enemies.enumerated() {
                if enemy.isAlive && !enemiesHit.contains(enemy.id) {
                    let dx = enemy.position.x - position.x
                    let dy = enemy.position.y - position.y
                    let dist = sqrt(dx*dx + dy*dy)
                    if dist < speed * 2 { // Close enough to hit
                        targetEnemy = enemy
                        targetIndex = index
                        break
                    }
                }
            }
            
            if targetEnemy == nil {
                // Continue forward
                let dx = cos(atan2(position.y - origin.y, position.x - origin.x))
                let dy = sin(atan2(position.y - origin.y, position.x - origin.x))
                position.x += dx * speed
                position.y += dy * speed
                
                // Remove if too far from origin
                let distFromOrigin = sqrt(pow(position.x - origin.x, 2) + pow(position.y - origin.y, 2))
                if distFromOrigin > 200 {
                    isAlive = false
                }
                return
            }
        } else {
            // Normal projectile targeting
            guard let index = gameState.enemies.firstIndex(where: { $0.id == targetId && $0.isAlive }) else {
                isAlive = false
                return
            }
            targetEnemy = gameState.enemies[index]
            targetIndex = index
        }
        
        guard let target = targetEnemy, targetIndex >= 0 else {
            isAlive = false
            return
        }
        
        let targetPos = target.position
        let dx = targetPos.x - position.x
        let dy = targetPos.y - position.y
        let dist = sqrt(dx*dx + dy*dy)
        
        if dist < speed {
            // Hit enemy
            if !enemiesHit.contains(target.id) {
                gameState.enemies[targetIndex].health -= damage
                if gameState.enemies[targetIndex].health <= 0 {
                    gameState.enemies[targetIndex].isAlive = false
                    gameState.coins += target.type.reward
                    gameState.score += target.type.reward * 2
                }
                enemiesHit.insert(target.id)
            }
            
            if !pierces {
                isAlive = false
            }
        } else {
            // Move toward target
            position.x += dx / dist * speed
            position.y += dy / dist * speed
        }
    }
}

// MARK: - AoE Blast Effect
struct AoEBlast: Identifiable {
    let id = UUID()
    var position: CGPoint
    var radius: CGFloat
    var createdAt: TimeInterval
}
