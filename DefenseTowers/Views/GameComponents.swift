//
//  GameComponents.swift
//  DefenseTowers
//
//  Individual view components for game entities
//

import SwiftUI

// MARK: - Enemy View
struct EnemyView: View {
    let enemy: Enemy
    
    var body: some View {
        ZStack {
            // Main enemy body matching Figma specs
            Circle()
                .fill(enemy.type.color)
                .frame(width: enemyFrameSize, height: enemyFrameSize)
                .background(Color(red: 0.9, green: 0.9, blue: 0.85))
                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
            
            // Health bar
            if enemy.healthPercentage < 1.0 {
                VStack {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: enemy.type.size + 4, height: 3)
                        .overlay(
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: (enemy.type.size + 4) * enemy.healthPercentage, height: 3),
                            alignment: .leading
                        )
                        .overlay(
                            Rectangle()
                                .stroke(Color.black.opacity(0.5), lineWidth: 0.5)
                        )
                    
                    Spacer()
                }
                .frame(height: enemy.type.size)
                .offset(y: -enemy.type.size/2 - 6)
            }
            
            // Enemy type indicator
            Text(enemyTypeIcon)
                .font(.system(size: enemy.type.size * 0.4))
                .foregroundColor(.white)
                .fontWeight(.bold)
        }
        .position(enemy.position)
    }
    
    private var enemyFrameSize: CGFloat {
        // Use Figma specs for different enemy types
        switch enemy.type {
        case .boss: return 37.35303 // Special size for boss from Figma
        default: return 34.95898 // Standard size from Figma
        }
    }
    
    private var enemyTypeIcon: String {
        switch enemy.type {
        case .basic: return "●"
        case .fast: return "▲"
        case .tank: return "■"
        case .swarm: return "◆"
        case .boss: return "★"
        }
    }
}

// MARK: - Tower View
struct TowerView: View {
    @ObservedObject var tower: Tower
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        ZStack {
            // Tower base matching Figma specs
            Image(systemName: towerIcon)
                .frame(width: 34.95898, height: 34.95898)
                .background(Color(red: 0.2, green: 0.27, blue: 0.35))
                .foregroundColor(Color(red: 0.92, green: 0.9, blue: 0.84))
                .font(.system(size: 16, weight: .bold))
                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
            
            // Upgrade indicators
            upgradeIndicators
            
            // Range indicator (when selected)
            if gameState.selectedTower?.id == tower.id {
                Circle()
                    .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .frame(width: tower.range * 2, height: tower.range * 2)
            }
        }
        .position(tower.position)
    }
    
    private var towerIcon: String {
        switch tower.type {
        case .peace: return "peacesign"
        case .tree: return "tree"
        case .wave: return "swirl.circle.righthalf.filled"
        case .sun: return "sun.max"
        case .moon: return "moon.haze"
        }
    }
    
    private var upgradeIndicators: some View {
        ZStack {
            // Pierce indicator
            if tower.canPierce {
                Circle()
                    .stroke(Color.yellow, lineWidth: 2)
                    .frame(width: 38, height: 38)
                    .shadow(color: .yellow, radius: 2)
            }
            
            // Range indicator
            if tower.hasExtremeRange {
                Circle()
                    .stroke(Color.green.opacity(0.6), lineWidth: 1)
                    .frame(width: 42, height: 42)
            }
            
            // Fast fire indicator
            if tower.hasFastFire {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange, lineWidth: 2)
                    .frame(width: 36, height: 36)
            }
        }
    }
    
}

// MARK: - Projectile View
struct ProjectileView: View {
    let projectile: Projectile
    
    var body: some View {
        Circle()
            .fill(projectileColor)
            .frame(width: projectileSize, height: projectileSize)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 1)
            )
            .shadow(color: projectileColor.opacity(0.5), radius: 2)
            .position(projectile.position)
    }
    
    private var projectileColor: Color {
        switch projectile.towerType {
        case .peace: return .cyan
        case .tree: return .green
        case .wave: return .blue
        case .sun: return projectile.pierces ? .orange : .yellow
        case .moon: return .purple
        }
    }
    
    private var projectileSize: CGFloat {
        switch projectile.towerType {
        case .peace: return 6
        case .tree: return 5
        case .wave: return 6
        case .sun: return projectile.pierces ? 8 : 7
        case .moon: return 7
        }
    }
}

// MARK: - AoE Blast View
struct AoEBlastView: View {
    let blast: AoEBlast
    
    var body: some View {
        Circle()
            .stroke(Color.orange.opacity(opacity), lineWidth: 4)
            .frame(width: blast.radius * 2, height: blast.radius * 2)
            .overlay(
                Circle()
                    .fill(Color.orange.opacity(opacity * 0.2))
                    .frame(width: blast.radius * 2, height: blast.radius * 2)
            )
            .position(blast.position)
            .scaleEffect(scale)
            .animation(.easeOut(duration: 0.3), value: scale)
    }
    
    private var opacity: Double {
        let elapsed = CACurrentMediaTime() - blast.createdAt
        return max(0, 1.0 - elapsed / 0.3)
    }
    
    private var scale: Double {
        let elapsed = CACurrentMediaTime() - blast.createdAt
        return 0.5 + (elapsed / 0.3) * 0.5
    }
}

// MARK: - Extensions for UpgradeType
extension UpgradeType: CaseIterable {
    public static var allCases: [UpgradeType] = [.pierce, .range, .fastFire]
}
