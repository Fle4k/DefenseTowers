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
    @Environment(\.scenePhase) private var scenePhase
    
    let rows = 12
    let cols = 10
    let cellSize: CGFloat = 40
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header with game info and play/pause button
                headerView
                
                // Game Board
                gameBoard
                    .frame(width: 393, height: 506.93481)
                    .background(
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(width: 393, height: 506.93481)
                            .background(Color(red: 0.65, green: 0.65, blue: 0.65))
                            .overlay(
                                Rectangle()
                                    .frame(width: 393, height: 506.93481)
                                    .background(Color(red: 0.2, green: 0.27, blue: 0.35))
                            )
                            .overlay(GridPattern())
                    )
                    .onTapGesture {
                        selectedTowerType = nil // Deselect tower when tapping elsewhere
                        gameState.selectedTower = nil
                    }
                
                Spacer()
                
                // Tower upgrade options (when tower selected)
                if gameState.selectedTower != nil {
                    towerUpgradeView
                }
                
                // Tower Selection Bar at bottom
                towerSelectionBar
            }
            .background(Color(red: 0.92, green: 0.9, blue: 0.84)) // #ebe6d6
            .onAppear {
                // Don't auto-start game
            }
            .onDisappear {
                gameState.stopGameLoop()
            }
            .alert("Game Over", isPresented: $showGameOver) {
                Button("Restart") {
                    gameState.resetGame()
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
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .background:
                    gameState.handleAppDidEnterBackground()
                case .active:
                    if gameState.showPauseOverlay {
                        // Don't auto-resume, let user choose
                    }
                default:
                    break
                }
            }
            .overlay(
                // Pause overlay
                Group {
                    if gameState.showPauseOverlay {
                        pauseOverlay
                    }
                }
            )
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                // Wave information
                Text("Wave \(max(1, gameState.currentWave))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.2, green: 0.27, blue: 0.35)) // #334559
                
                Spacer()
                
                // Play/Pause button or Start Wave button
                if gameState.gameState == .playing && gameState.waveManager.canStartNextWave {
                    Button(action: {
                        gameState.waveManager.startNextWave()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.title2)
                            Text("Wave")
                                .font(.title3)
                        }
                        .foregroundColor(.green)
                    }
                } else {
                    Button(action: {
                        if gameState.gameState == .notStarted {
                            gameState.startGameLoop()
                            gameState.waveManager.startNextWave()
                        } else if gameState.gameState == .playing {
                            gameState.pauseGame()
                        } else if gameState.gameState == .paused {
                            gameState.resumeGame()
                        }
                    }) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.92, green: 0.9, blue: 0.84)) // #ebe6d6
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: gameState.gameState == .playing ? "pause.fill" : "play.fill")
                                    .font(.title2)
                                    .foregroundColor(Color(red: 0.2, green: 0.27, blue: 0.35)) // #334559
                            )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Second row with score, currency, and escaped
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Score")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.2, green: 0.27, blue: 0.35)) // #334559
                    
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.black)
                            .font(.system(size: 16))
                        Text("\(gameState.coins)")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                    }
                }
                
                Spacer()
                
                Text("Escaped \(gameState.enemiesEscaped)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(red: 0.92, green: 0.9, blue: 0.84)) // #ebe6d6
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
                        isPlaceable: selectedTowerType != nil && !isPath && !isOccupied,
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
                    .onTapGesture {
                        gameState.selectedTower = tower
                    }
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
        VStack(spacing: 12) {
            // Tower icons row
            HStack(spacing: 20) {
                ForEach(TowerType.allCases, id: \.self) { towerType in
                    Button(action: {
                        selectedTowerType = selectedTowerType == towerType ? nil : towerType
                    }) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.2, green: 0.27, blue: 0.35)) // #334559
                            .frame(width: 34.95898, height: 34.95898)
                            .overlay(
                                Image(systemName: towerIcon(for: towerType))
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(red: 0.92, green: 0.9, blue: 0.84)) // #ebe6d6
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedTowerType == towerType ? Color.blue : Color.clear, lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 4)
                    }
                    .disabled(gameState.coins < towerType.cost)
                    .opacity(gameState.coins >= towerType.cost ? 1.0 : 0.5)
                }
            }
            
            // Price row
            HStack(spacing: 20) {
                ForEach(TowerType.allCases, id: \.self) { towerType in
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(Color(red: 0.2, green: 0.27, blue: 0.35)) // #334559
                            .font(.system(size: 16))
                        Text("\(towerType.cost)")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.2, green: 0.27, blue: 0.35)) // #334559
                    }
                    .frame(width: 34.95898)
                }
            }
        }
        .padding()
        .background(Color(red: 0.92, green: 0.9, blue: 0.84)) // #ebe6d6
    }
    
    private var towerUpgradeView: some View {
        guard let selectedTower = gameState.selectedTower else { return AnyView(EmptyView()) }
        
        return AnyView(
            VStack(spacing: 8) {
                // Upgrade options row
                HStack(spacing: 20) {
                    ForEach(UpgradeType.allCases, id: \.self) { upgradeType in
                        if selectedTower.canUpgrade(upgradeType) {
                            Button(action: {
                                let cost = selectedTower.getUpgradeCost(upgrade: upgradeType)
                                if gameState.coins >= cost {
                                    selectedTower.applyUpgrade(upgradeType)
                                    gameState.coins -= cost
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(gameState.coins >= selectedTower.getUpgradeCost(upgrade: upgradeType) ? Color.blue : Color.gray.opacity(0.6))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Text(upgradeIcon(for: upgradeType))
                                                .font(.caption)
                                                .foregroundColor(.white)
                                        )
                                    Text(upgradeType.displayName)
                                        .font(.caption2)
                                        .foregroundColor(.black)
                                        .fontWeight(.medium)
                                }
                            }
                            .disabled(gameState.coins < selectedTower.getUpgradeCost(upgrade: upgradeType))
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(Color(red: 0.92, green: 0.9, blue: 0.84)) // #ebe6d6
        )
    }
    
    private func upgradeIcon(for upgradeType: UpgradeType) -> String {
        switch upgradeType {
        case .pierce: return "🔫"
        case .range: return "🎯"
        case .fastFire: return "⚡"
        }
    }
    
    private func towerIcon(for towerType: TowerType) -> String {
        switch towerType {
        case .peace: return "peacesign"
        case .tree: return "tree"
        case .wave: return "swirl.circle.righthalf.filled"
        case .sun: return "sun.max"
        case .moon: return "moon.haze"
        }
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
    
    
    private var pauseOverlay: some View {
        Color.black.opacity(0.7)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 20) {
                    Text("Game Paused")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            gameState.resumeGame()
                        }) {
                            Text("Continue")
                                .font(.headline)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            gameState.resetGame()
                        }) {
                            Text("Restart")
                                .font(.headline)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
            )
    }
}

// MARK: - Supporting Views

struct GridTileView: View {
    let position: CGPoint
    let isPath: Bool
    let isOccupied: Bool
    let isSelected: Bool
    let isPlaceable: Bool
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
        } else if isPlaceable {
            return Color.gray.opacity(0.2) // Gray surrounding when placing towers
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

struct GridPattern: View {
    var body: some View {
        Canvas { context, size in
            let cellSize: CGFloat = 40
            let rows = Int(size.height / cellSize)
            let cols = Int(size.width / cellSize)
            
            context.stroke(
                Path { path in
                    for i in 0...cols {
                        let x = CGFloat(i) * cellSize
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    for i in 0...rows {
                        let y = CGFloat(i) * cellSize
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                },
                with: .color(Color(red: 0.92, green: 0.9, blue: 0.84).opacity(0.1)), // #ebe6d6 with opacity
                lineWidth: 2
            )
        }
    }
}

#Preview {
    GameView()
}
