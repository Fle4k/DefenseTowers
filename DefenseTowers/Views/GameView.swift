//
//  GameView.swift
//  DefenseTowers
//
//  Main game view with grid, towers, enemies, and UI
//

import SwiftUI

struct GameView: View {
    @StateObject private var gameState = GameState()
    @State private var selectedTowerType: TowerType? = nil
    @State private var showGameOver = false
    
    let rows = 12
    let cols = 10
    let cellSize: CGFloat = 40
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // HUD
                gameHUD
                
                // Game Board
                gameBoard
                    .frame(width: CGFloat(cols) * cellSize, height: CGFloat(rows) * cellSize)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black.opacity(0.3), lineWidth: 2)
                    )
                
                Spacer()
                
                // Tower Selection Bar
                towerSelectionBar
            }
            .padding()
            .onAppear {
                gameState.startGameLoop()
            }
            .onDisappear {
                gameState.stopGameLoop()
            }
            .alert("Game Over", isPresented: $showGameOver) {
                Button("Restart") {
                    gameState.resetGame()
                    gameState.startGameLoop()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Final Score: \(gameState.score)\nWaves Survived: \(gameState.currentWave)")
            }
            .onChange(of: gameState.gameOver) { _, newValue in
                if newValue {
                    showGameOver = true
                    gameState.stopGameLoop()
                }
            }
        }
    }
    
    private var gameHUD: some View {
        HStack {
            // Health
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("\(gameState.health)")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            // Coins
            HStack(spacing: 4) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.yellow)
                Text("\(gameState.coins)")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            // Wave info
            VStack(spacing: 2) {
                Text("Wave \(gameState.currentWave)")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("Score: \(gameState.score)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Start Wave Button
            Button(action: {
                if gameState.waveManager.canStartNextWave {
                    gameState.waveManager.startNextWave()
                }
            }) {
                Text(gameState.waveManager.canStartNextWave ? "Start Wave" : "Wave Active")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(gameState.waveManager.canStartNextWave ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            .disabled(!gameState.waveManager.canStartNextWave)
        }
        .padding()
        .background(Color.black.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var gameBoard: some View {
        ZStack {
            // Grid tiles
            ForEach(0..<rows, id: \.self) { row in
                ForEach(0..<cols, id: \.self) { col in
                    let tileCenter = CGPoint(
                        x: CGFloat(col) * cellSize + cellSize/2,
                        y: CGFloat(row) * cellSize + cellSize/2
                    )
                    let isPath = gameState.waveManager.pathCells.contains { $0 == (row, col) }
                    let isOccupied = gameState.towers.contains { tower in
                        let towerCol = Int((tower.position.x - cellSize/2) / cellSize)
                        let towerRow = Int((tower.position.y - cellSize/2) / cellSize)
                        return towerRow == row && towerCol == col
                    }
                    
                    GridTileView(
                        position: tileCenter,
                        isPath: isPath,
                        isOccupied: isOccupied,
                        isSelected: selectedTowerType != nil && !isPath && !isOccupied,
                        cellSize: cellSize
                    )
                    .onTapGesture {
                        if !isPath && !isOccupied, let towerType = selectedTowerType {
                            placeTower(type: towerType, at: (row, col))
                        }
                    }
                }
            }
            
            // Path visualization
            PathView(path: gameState.waveManager.path)
            
            // Towers
            ForEach(gameState.towers) { tower in
                TowerView(tower: tower)
                    .environmentObject(gameState)
            }
            
            // Enemies
            ForEach(gameState.enemies) { enemy in
                EnemyView(enemy: enemy)
            }
            
            // Projectiles
            ForEach(gameState.projectiles) { projectile in
                ProjectileView(projectile: projectile)
            }
            
            // AoE Blasts
            ForEach(gameState.blasts) { blast in
                AoEBlastView(blast: blast)
            }
        }
    }
    
    private var towerSelectionBar: some View {
        HStack(spacing: 12) {
            ForEach(TowerType.allCases, id: \.self) { towerType in
                TowerSelectionButton(
                    towerType: towerType,
                    isSelected: selectedTowerType == towerType,
                    canAfford: gameState.coins >= towerType.cost
                ) {
                    selectedTowerType = selectedTowerType == towerType ? nil : towerType
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func placeTower(type: TowerType, at cell: (Int, Int)) {
        guard gameState.coins >= type.cost else { return }
        
        let (row, col) = cell
        let position = CGPoint(
            x: CGFloat(col) * cellSize + cellSize/2,
            y: CGFloat(row) * cellSize + cellSize/2
        )
        
        let tower = Tower(type: type, position: position)
        gameState.towers.append(tower)
        gameState.coins -= type.cost
        selectedTowerType = nil // Deselect after placing
    }
}

// MARK: - Supporting Views

struct GridTileView: View {
    let position: CGPoint
    let isPath: Bool
    let isOccupied: Bool
    let isSelected: Bool
    let cellSize: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(tileColor)
            .frame(width: cellSize, height: cellSize)
            .position(position)
            .overlay(
                Rectangle()
                    .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                    .frame(width: cellSize, height: cellSize)
                    .position(position)
            )
    }
    
    private var tileColor: Color {
        if isPath {
            return Color.brown.opacity(0.6)
        } else if isOccupied {
            return Color.gray.opacity(0.3)
        } else if isSelected {
            return Color.blue.opacity(0.3)
        } else {
            return Color.green.opacity(0.2)
        }
    }
}

struct PathView: View {
    let path: [CGPoint]
    
    var body: some View {
        Path { path in
            guard self.path.count > 1 else { return }
            
            path.move(to: self.path[0])
            for point in self.path.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(Color.brown.opacity(0.8), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
    }
}

struct TowerSelectionButton: View {
    let towerType: TowerType
    let isSelected: Bool
    let canAfford: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Tower icon
                RoundedRectangle(cornerRadius: 4)
                    .fill(towerType.color)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(towerType.displayName.prefix(1))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                Text(towerType.displayName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                
                HStack(spacing: 2) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text("\(towerType.cost)")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
            }
            .padding(8)
            .frame(minWidth: 70)
            .background(backgroundcolor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isSelected)
        }
        .disabled(!canAfford)
    }
    
    private var backgroundcolor: Color {
        if !canAfford {
            return Color.gray.opacity(0.3)
        } else if isSelected {
            return Color.blue.opacity(0.2)
        } else {
            return Color.white
        }
    }
    
    private var borderColor: Color {
        if !canAfford {
            return Color.gray
        } else if isSelected {
            return Color.blue
        } else {
            return Color.black.opacity(0.2)
        }
    }
}

#Preview {
    GameView()
}
