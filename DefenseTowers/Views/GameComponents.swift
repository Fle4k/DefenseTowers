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
            // Main enemy body
            Circle()
                .fill(enemy.type.color)
                .frame(width: enemy.type.size, height: enemy.type.size)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                )
            
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
    @State private var showUpgradeMenu = false
    
    var body: some View {
        ZStack {
            // Tower base
            RoundedRectangle(cornerRadius: 6)
                .fill(tower.type.color)
                .frame(width: 32, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.black.opacity(0.4), lineWidth: 2)
                )
                .overlay(
                    Text(towerIcon)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                )
            
            // Upgrade indicators
            upgradeIndicators
            
            // Range indicator (when selected)
            if showUpgradeMenu {
                Circle()
                    .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .frame(width: tower.range * 2, height: tower.range * 2)
            }
            
            // Upgrade menu
            if showUpgradeMenu {
                upgradeMenu
            }
        }
        .position(tower.position)
        .onTapGesture {
            showUpgradeMenu.toggle()
        }
        .onTapGesture(count: 2) {
            showUpgradeMenu = false
        }
    }
    
    private var towerIcon: String {
        switch tower.type {
        case .basic: return "⚡"
        case .sniper: return "🎯"
        case .aoe: return "💥"
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
    
    private var upgradeMenu: some View {
        VStack(spacing: 4) {
            ForEach(availableUpgrades, id: \.self) { upgrade in
                upgradeButton(for: upgrade)
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.95))
        .cornerRadius(8)
        .shadow(radius: 4)
        .position(x: tower.position.x, y: tower.position.y - 60)
    }
    
    private var availableUpgrades: [UpgradeType] {
        UpgradeType.allCases.filter { tower.canUpgrade($0) }
    }
    
    private func upgradeButton(for upgrade: UpgradeType) -> some View {
        Button(action: {
            let cost = tower.getUpgradeCost(upgrade: upgrade)
            if gameState.coins >= cost {
                tower.applyUpgrade(upgrade)
                gameState.coins -= cost
            }
        }) {
            HStack(spacing: 4) {
                Text(upgrade.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                
                HStack(spacing: 2) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text("\(tower.getUpgradeCost(upgrade: upgrade))")
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(gameState.coins >= tower.getUpgradeCost(upgrade: upgrade) ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(4)
        }
        .disabled(gameState.coins < tower.getUpgradeCost(upgrade: upgrade))
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
        case .basic: return .cyan
        case .sniper: return projectile.pierces ? .purple : .indigo
        case .aoe: return .orange
        }
    }
    
    private var projectileSize: CGFloat {
        switch projectile.towerType {
        case .basic: return 6
        case .sniper: return projectile.pierces ? 8 : 5
        case .aoe: return 7
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
