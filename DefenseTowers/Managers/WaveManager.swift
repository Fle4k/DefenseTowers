//
//  WaveManager.swift
//  DefenseTowers
//
//  Wave management system for spawning enemies
//

import SwiftUI
import Foundation

class WaveManager {
    weak var gameState: GameState?
    private var waveInProgress = false
    private var enemySpawnTimer: Timer?
    
    // Grid configuration
    let cellSize: CGFloat = 40
    let rows = 12
    let cols = 10
    
    init(gameState: GameState) {
        self.gameState = gameState
    }
    
    // Define path in grid coordinates (row, col)
    var pathCells: [(Int, Int)] {
        [
            // Start from left side
            (5, 0), (5, 1), (5, 2), (5, 3),
            // Turn up
            (4, 3), (3, 3), (2, 3),
            // Turn right
            (2, 4), (2, 5), (2, 6), (2, 7),
            // Turn down
            (3, 7), (4, 7), (5, 7), (6, 7), (7, 7),
            // Turn left
            (7, 6), (7, 5), (7, 4),
            // Turn down
            (8, 4), (9, 4), (10, 4), (11, 4)
        ]
    }
    
    // Convert grid cells to CGPoint positions
    var path: [CGPoint] {
        pathCells.map { (r, c) in
            CGPoint(
                x: CGFloat(c) * cellSize + cellSize/2,
                y: CGFloat(r) * cellSize + cellSize/2
            )
        }
    }
    
    var spawnPoint: CGPoint {
        path.first ?? .zero
    }
    
    var goalPoint: CGPoint {
        path.last ?? .zero
    }
    
    func startNextWave() {
        guard let gameState = gameState, !waveInProgress else { return }
        
        waveInProgress = true
        gameState.currentWave += 1
        
        let waveConfig = getWaveConfiguration(wave: gameState.currentWave)
        var enemyIndex = 0
        let totalEnemies = waveConfig.reduce(0) { $0 + $1.count }
        
        enemySpawnTimer = Timer.scheduledTimer(withTimeInterval: waveConfig.first?.spawnInterval ?? 1.0, repeats: true) { [weak self] timer in
            guard let self = self, let gameState = self.gameState else {
                timer.invalidate()
                return
            }
            
            // Find which enemy type to spawn
            var currentCount = 0
            var enemyTypeToSpawn: EnemyType = .basic
            
            for config in waveConfig {
                if enemyIndex < currentCount + config.count {
                    enemyTypeToSpawn = config.type
                    break
                }
                currentCount += config.count
            }
            
            // Create and spawn enemy
            let healthMultiplier = 1.0 + (Double(gameState.currentWave - 1) * 0.3)
            let enemy = Enemy(
                type: enemyTypeToSpawn,
                position: self.spawnPoint,
                path: self.path,
                waveMultiplier: healthMultiplier
            )
            
            gameState.enemies.append(enemy)
            enemyIndex += 1
            
            // Check if wave is complete
            if enemyIndex >= totalEnemies {
                timer.invalidate()
                self.enemySpawnTimer = nil
                
                // Wait for all enemies to be cleared before allowing next wave
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.waveInProgress = false
                }
            }
        }
    }
    
    private func getWaveConfiguration(wave: Int) -> [WaveEnemyConfig] {
        switch wave {
        case 1:
            return [
                WaveEnemyConfig(type: .basic, count: 8, spawnInterval: 1.0)
            ]
        case 2:
            return [
                WaveEnemyConfig(type: .basic, count: 6, spawnInterval: 0.8),
                WaveEnemyConfig(type: .fast, count: 4, spawnInterval: 0.8)
            ]
        case 3:
            return [
                WaveEnemyConfig(type: .basic, count: 8, spawnInterval: 0.7),
                WaveEnemyConfig(type: .tank, count: 2, spawnInterval: 0.7)
            ]
        case 4:
            return [
                WaveEnemyConfig(type: .swarm, count: 12, spawnInterval: 0.5),
                WaveEnemyConfig(type: .fast, count: 6, spawnInterval: 0.5)
            ]
        case 5:
            return [
                WaveEnemyConfig(type: .basic, count: 10, spawnInterval: 0.6),
                WaveEnemyConfig(type: .tank, count: 3, spawnInterval: 0.6),
                WaveEnemyConfig(type: .boss, count: 1, spawnInterval: 0.6)
            ]
        default:
            // Progressive difficulty for waves 6+
            let baseEnemies = 8 + (wave - 5) * 2
            let fastEnemies = 4 + (wave - 5)
            let tankEnemies = 2 + (wave - 5) / 2
            let bossCount = (wave - 4) / 3
            
            var config = [
                WaveEnemyConfig(type: .basic, count: baseEnemies, spawnInterval: max(0.3, 0.8 - Double(wave) * 0.05)),
                WaveEnemyConfig(type: .fast, count: fastEnemies, spawnInterval: max(0.3, 0.8 - Double(wave) * 0.05))
            ]
            
            if tankEnemies > 0 {
                config.append(WaveEnemyConfig(type: .tank, count: tankEnemies, spawnInterval: max(0.3, 0.8 - Double(wave) * 0.05)))
            }
            
            if wave % 3 == 0 {
                config.append(WaveEnemyConfig(type: .swarm, count: 8 + wave, spawnInterval: 0.3))
            }
            
            if bossCount > 0 {
                config.append(WaveEnemyConfig(type: .boss, count: bossCount, spawnInterval: max(0.3, 0.8 - Double(wave) * 0.05)))
            }
            
            return config
        }
    }
    
    var canStartNextWave: Bool {
        return !waveInProgress && gameState?.enemies.isEmpty == true
    }
    
    func stopCurrentWave() {
        enemySpawnTimer?.invalidate()
        enemySpawnTimer = nil
        waveInProgress = false
    }
}

struct WaveEnemyConfig {
    let type: EnemyType
    let count: Int
    let spawnInterval: TimeInterval
}
