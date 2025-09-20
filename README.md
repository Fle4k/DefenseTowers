# DefenseTowers - SwiftUI Tower Defense Game

A fully-featured tower defense game built with SwiftUI for iOS, featuring multiple enemy types, tower upgrades, wave management, and engaging gameplay mechanics.

## 🎮 Game Features

### Core Gameplay
- **Grid-based battlefield** with a predefined enemy path
- **Real-time combat** with 60 FPS game loop
- **Progressive wave system** with increasing difficulty
- **Economy system** - earn coins by defeating enemies
- **Health management** - lose HP when enemies reach the base
- **Score tracking** and game over conditions

### Enemy Types (5 Total)
1. **Basic Enemy** (Red) - Standard health and speed
2. **Fast Enemy** (Yellow) - High speed, low health
3. **Tank Enemy** (Purple) - High health, slow speed, deals more damage
4. **Swarm Enemy** (Orange) - Low health, spawns in large numbers
5. **Boss Enemy** (Black) - Very high health and damage

### Tower Types (3 Total)
1. **Basic Tower** (Blue) - Balanced damage and range
   - Upgrade: Fast Fire - doubles attack speed
2. **Sniper Tower** (Purple) - High damage, long range, slow fire rate
   - Upgrade: Pierce - projectiles pass through enemies
   - Upgrade: Extreme Range - 40% increased range
3. **AoE Tower** (Orange) - Area damage to all enemies in range

### Visual Features
- **Health bars** for damaged enemies
- **Range indicators** when selecting towers
- **Upgrade indicators** with glowing effects
- **Projectile trails** with different colors per tower type
- **AoE blast effects** with animated explosions
- **Path visualization** showing enemy route

## 🏗️ Architecture

### Project Structure
```
DefenseTowers/
├── Models/
│   └── GameModels.swift          # Core game entities and logic
├── Managers/
│   └── WaveManager.swift         # Wave spawning and progression
├── Views/
│   ├── GameView.swift            # Main game interface
│   └── GameComponents.swift      # Individual UI components
├── ContentView.swift             # App entry point
└── DefenseTowersApp.swift        # App configuration
```

### Core Components

#### GameState (ObservableObject)
- Manages all game entities and state
- Handles the main game loop (60 FPS)
- Coordinates between towers, enemies, and projectiles
- Manages economy and health systems

#### Enemy System
- 5 distinct enemy types with unique stats
- Health scaling based on wave number
- Pathfinding along predefined waypoints
- Visual health bars and type indicators

#### Tower System
- 3 tower types with unique behaviors
- Upgrade system with visual feedback
- Smart targeting (furthest along path)
- Different projectile types and effects

#### Wave Management
- Progressive difficulty scaling
- Mixed enemy compositions per wave
- Timed enemy spawning
- Boss waves every few rounds

## 🎯 Gameplay Mechanics

### Tower Placement
- Tap tower type to select
- Tap empty grid tile to place
- Visual feedback for valid placement areas
- Automatic deselection after placement

### Tower Upgrades
- Tap placed towers to open upgrade menu
- Multiple upgrade paths per tower type
- Visual indicators for applied upgrades
- Cost-based upgrade system

### Enemy Targeting
- Towers automatically target enemies in range
- Priority: enemies furthest along the path
- Projectiles track moving targets
- AoE towers hit all enemies in range simultaneously

### Wave Progression
- Manual wave start with "Start Wave" button
- Increasing enemy counts and health
- New enemy types introduced gradually
- Boss enemies every few waves

## 🔧 Technical Implementation

### SwiftUI Architecture
- **MVVM pattern** with ObservableObject
- **Combine framework** for reactive updates
- **GeometryReader** for responsive layout
- **Animation system** for visual effects

### Performance Optimizations
- Efficient collision detection
- Object pooling for projectiles
- Optimized drawing with position-based rendering
- 60 FPS game loop with Timer.publish

### Game Loop
```swift
func update() {
    // Move enemies along path
    // Update tower targeting and firing
    // Move projectiles and check collisions
    // Remove dead objects
    // Update visual effects
}
```

## 🎨 Visual Design

### Color Scheme
- **Green tiles** - Buildable areas
- **Brown path** - Enemy route
- **Blue/Purple/Orange** - Tower types
- **Red/Yellow/Purple/Orange/Black** - Enemy types

### UI Elements
- Clean, modern interface
- SF Symbols for icons
- Consistent spacing and typography
- Responsive design for different screen sizes

## 🚀 Getting Started

### Requirements
- iOS 18.2+
- Xcode 16.0+
- Swift 5.0+

### Installation
1. Clone the repository
2. Open `DefenseTowers.xcodeproj` in Xcode
3. Build and run on iOS Simulator or device

### Controls
- **Tap** tower buttons to select tower type
- **Tap** empty tiles to place towers
- **Tap** placed towers to view upgrades
- **Tap** "Start Wave" to begin next wave

## 🎮 Gameplay Tips

1. **Start with Basic towers** - They're cost-effective early game
2. **Block chokepoints** - Place towers where enemies bunch up
3. **Upgrade strategically** - Pierce for Snipers, Range for coverage
4. **Save for boss waves** - Keep coins for powerful enemies
5. **Mix tower types** - Combine AoE and single-target damage

## 🔮 Future Enhancements

- More tower types and upgrades
- Additional enemy varieties
- Power-ups and special abilities
- Multiple maps and paths
- Leaderboards and achievements
- Sound effects and music
- Particle effects for explosions

## 📝 Code Quality

- **Swift best practices** - Value types, optionals, protocols
- **Clean architecture** - Separation of concerns
- **Comprehensive documentation** - Inline comments and README
- **Type safety** - Strong typing throughout
- **Performance optimized** - 60 FPS smooth gameplay

---

Built with ❤️ using SwiftUI and following Apple's design guidelines.
