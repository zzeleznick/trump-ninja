//
//  GameScene.swift
//  WhiteHouseDonald
//
//  Created by Zach Zeleznick on 10/16/16.
//  Copyright © 2016 zzeleznick. All rights reserved.
//

import AVFoundation
import SpriteKit
import GameKit

enum Bomb {
    case never, always, random
}

enum SequenceType: Int {
    case oneNoBomb=0, one, twoWithOneBomb, two, three, four, chain, fastChain
}

enum Level:Int {
    case normal=0, expert, legendary, god
}

enum Powerup:Int {
    case none=0, invicible
}

class GameScene: SKScene {
    var iPad: Bool = false
    var vw: CGFloat!
    var vh: CGFloat!
    
    let generator = RandomGenerator()
    var prefs: UserDefaults!
    
    var gameScore: SKLabelNode!
    var score: Int = 0 {
        didSet {
            guard gameScore != nil else { return }
            gameScore.text = "Score: \(score)"
        }
    }
    var bestScoreLabel: SKLabelNode!
    var bestScore: Int = 0 {
        didSet {
            guard bestScoreLabel != nil else { return }
            bestScoreLabel.text = "High Score: \(bestScore)"
        }
    }
    var livesImages = [SKSpriteNode]()
    var lives = 3
    
    var hiddenElement: UIView!
    var powerup = Powerup.none
    
    var activeSliceBG: SKShapeNode!
    var activeSliceFG: SKShapeNode!
    var activeSlicePoints = [CGPoint]()
    
    var activeEnemies = [SKSpriteNode]()
    var isSwooshSoundActive = false
    var bombSoundEffect: AVAudioPlayer!
    
    var overlayActive = false
    struct Base {
        static var speed: CGFloat = 0.75
        static var gravity = CGVector(dx: 0, dy: -6)
        static var popupTime = 1.2
        static var chainDelay = 4.0
    }

    var sequence: [SequenceType]!
    var sequencePosition = 0
    
    var gameSpeed: CGFloat = 0.75 {
        didSet {
            if !overlayActive {
                physicsWorld.speed = gameSpeed
            }
        }
    }
    var popupTime = 1.2
    var chainDelay = 4.0
    
    var nextSequenceQueued = true
    var gameEnded = false
    
    
    override func didMove(to view: SKView) {
        print("Moved to view")
        
        vh = view.frame.height
        vw = view.frame.width
        let doubleTap = UITapGestureRecognizer(target: self,
                                               action: #selector(handleDoubleTap))
        doubleTap.numberOfTouchesRequired = 2
        doubleTap.numberOfTapsRequired = 3
        view.addGestureRecognizer(doubleTap)
        
        resetWorld()
        setupView()
        startTossing()
    }
    
    func resetWorld() {
        gameEnded = false
        physicsWorld.gravity = Base.gravity
        gameSpeed = Base.speed
        popupTime = Base.popupTime
        chainDelay = Base.chainDelay
    }
    func resetScene() {
        removeAllChildren()
        activeEnemies = [SKSpriteNode]()
        setupView()
        startTossing()
    }
    func addHiddenElements() {
        hiddenElement = UIView(frame: CGRect(x: 20, y: 100,
                                            width: 100, height: 200))
        hiddenElement.alpha = 0
        // add powerup label
        let powerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        powerLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 24)
        powerLabel.text = "Cheat"
        hiddenElement.addSubview(powerLabel)
        // add powerup switch
        let switchy = UISwitch(frame: CGRect(x: 0, y: 60, width: 100, height: 80))
        switch powerup {
        case .invicible:
            switchy.isOn = true
        default:
            break
        }
        switchy.addTarget(self, action: #selector(switchToggled), for: UIControlEvents.valueChanged)
        hiddenElement.addSubview(switchy)
        view?.addSubview(hiddenElement)
    }
    
    func setupView() {
        let background = SKSpriteNode(imageNamed: "download-4")
        background.position = CGPoint(x: vw/2, y: vh/2)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        prefs = UserDefaults.standard
        addHiddenElements()
        
        showBegin()
        createScore()
        createLives()
        createSlices()
        playPhrase()
    }
    
    func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        print("[ZZ] Double Tappped")
        if sender.state == .ended && !overlayActive {
            overlayActive = true
            print("[ZZ] End Double Tapped")
            physicsWorld.speed = 0
            let overlay = SKShapeNode(rectOf: CGSize(width: vw, height: vh))
            overlay.position = CGPoint(x: vw/2, y: vh/2)
            overlay.name = "overlay"
            overlay.fillColor = SKColor.black
            overlay.alpha = 0.4
            // add pause label
            let label = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
            label.text = "Paused"
            label.horizontalAlignmentMode = .center
            label.fontSize = 48
            label.position = CGPoint(x: 0, y: vh/2-100)
            overlay.addChild(label)
            addChild(overlay)
            hiddenElement.alpha = 1
        }
    }
    func switchToggled(_ sender: UISwitch) {
        if sender.isOn {
            powerup = Powerup.invicible
            print("[ZZ]: Invicible")
        } else {
            powerup = Powerup.none
            print("[ZZ]: No powerup")
        }
    }
    func handleOverlay(node: SKNode) {
        print("[ZZ] Pressed overlay")
        if overlayActive {
            node.run(SKAction.fadeOut(withDuration: 1.0))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) { [unowned self] in
                node.removeFromParent()
                self.physicsWorld.speed = self.gameSpeed
            }
        }
        overlayActive = false
        hiddenElement.alpha = 0
    }
    
    func showBegin() {
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        label.text = "Begin"
        label.horizontalAlignmentMode = .center
        label.alpha = 0.0
        label.fontSize = 48
        label.position = CGPoint(x: vw/2, y: vh/2)
        addChild(label)
        label.run(SKAction.fadeIn(withDuration: 2.0))
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) {
            label.run(fadeAway())
        }
    }
    
    func showLoss() {
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        label.text = "Game Over"
        label.horizontalAlignmentMode = .center
        label.alpha = 0.0
        label.fontSize = 48
        label.position = CGPoint(x: vw/2, y: vh)
        addChild(label)
        let group = SKAction.group([SKAction.moveTo(y: vh/2, duration: 2.0),
                                    SKAction.fadeIn(withDuration: 2.0)])
        label.run(group)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) {
            label.run(fadeAway())
        }
    }
    
    func showWaveNumber() {
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        label.text = "Wave \(sequencePosition+1)"
        label.horizontalAlignmentMode = .center
        label.alpha = 0.0
        label.fontSize = 48
        label.position = CGPoint(x: vw/2, y: vh)
        addChild(label)
        let group = SKAction.group([SKAction.moveTo(y: vh/2, duration: 2.0),
                                    SKAction.fadeIn(withDuration: 2.0)])
        label.run(group)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) {
            label.run(fadeAway())
        }
    }
    func playPhrase() {
        let phrase = getRandomPhrase()
        run(SKAction.playSoundFileNamed("\(phrase)", waitForCompletion: false))
    }
    
    func startTossing() {
        sequencePosition = 0
        sequence = [.oneNoBomb, .oneNoBomb, .twoWithOneBomb, .twoWithOneBomb,
                    .three, .two, .chain]
        
        for _ in 0 ... 1000 {
            let nextSequence = SequenceType(rawValue: RandomInt(min: 2, max: 7))!
            sequence.append(nextSequence)
        }
        
        // NOTE: Game will crash if sequence position exceeds set
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [unowned self] in
            self.tossEnemies()
        }
    }
    
    func createScore() {
        score = 0
        gameScore = SKLabelNode(fontNamed: "Helvetica")
        gameScore.text = "Score: \(score)"
        gameScore.horizontalAlignmentMode = .left
        gameScore.fontSize = 24
        gameScore.position = CGPoint(x: 20, y: 20)
        addChild(gameScore)
        
        if let best = prefs.value(forKey: "best") as? Int {
            bestScore = best
        } else {
            prefs.set(bestScore, forKey: "best")
        }
        bestScoreLabel = SKLabelNode(fontNamed: "Helvetica")
        bestScoreLabel.text = "High Score: \(bestScore)"
        bestScoreLabel.horizontalAlignmentMode = .left
        bestScoreLabel.fontSize = 24
        bestScoreLabel.position = CGPoint(x: 20, y: vh-30)
        addChild(bestScoreLabel)
        
        
    }
    
    func createLives() {
        lives = 3
        livesImages = [SKSpriteNode]()
        let span: CGFloat = vw / 3.0 - 5.0
        let offset: CGFloat = span / 3.0
        for i in 0 ..< 3 {
            let spriteNode = SKSpriteNode(imageNamed: "sliceLife")
            spriteNode.size = CGSize(width: offset*0.75, height: offset*0.75)
            // NOTE: origin (0,0) is left bottom corner
            spriteNode.position = CGPoint(x: vw-span + (CGFloat(i) * offset), y: vh-40)
            addChild(spriteNode)
            livesImages.append(spriteNode)
        }
    }
    
    func createSlices() {
        activeSliceBG = SKShapeNode()
        activeSliceBG.zPosition = 2
        
        activeSliceFG = SKShapeNode()
        activeSliceFG.zPosition = 2
        
        activeSliceBG.strokeColor = UIColor(red: 1, green: 0.9, blue: 0, alpha: 1)
        activeSliceBG.lineWidth = 9
        
        activeSliceFG.strokeColor = UIColor.white
        activeSliceFG.lineWidth = 5
        
        addChild(activeSliceBG)
        addChild(activeSliceFG)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        activeSlicePoints.removeAll(keepingCapacity: true)
        
        if let touch = touches.first {
            let location = touch.location(in: self)
            activeSlicePoints.append(location)
            
            redrawActiveSlice()
    
            activeSliceBG.removeAllActions()
            activeSliceFG.removeAllActions()
            
            activeSliceBG.alpha = 1
            activeSliceFG.alpha = 1
        }
    }
    
    func handleEnemy(node: SKNode) {
        let emitter = SKEmitterNode(fileNamed: "sliceHitEnemy")!
        emitter.position = node.position
        addChild(emitter)

        node.name = ""
        node.physicsBody!.isDynamic = false
        node.run(fadeAway())
        
        let index = activeEnemies.index(of: node as! SKSpriteNode)!
        activeEnemies.remove(at: index)
        
        run(SKAction.playSoundFileNamed("whack.caf", waitForCompletion: false))
        score += 1
    }
    func handleBomb(node: SKNode) {
        let emitter = SKEmitterNode(fileNamed: "sliceHitBomb")!
        emitter.position = node.parent!.position
        addChild(emitter)
        
        node.name = ""
        node.parent!.physicsBody!.isDynamic = false
        node.parent!.run(fadeAway())

        let index = activeEnemies.index(of: node.parent as! SKSpriteNode)!
        activeEnemies.remove(at: index)
        
        run(SKAction.playSoundFileNamed("explosion.caf", waitForCompletion: false))
        if powerup != .invicible {
            endGame(triggeredByBomb: true)
        }
        else {
            gameSpeed *= 1.02
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameEnded {
            return
        }
        
        guard let touch = touches.first else { return }
        
        let location = touch.location(in: self)
        
        activeSlicePoints.append(location)
        redrawActiveSlice()
        
        if !isSwooshSoundActive {
            playSwooshSound()
        }
        
        let nodesAtPoint = nodes(at: location)
        
        for node in nodesAtPoint {
            if let name: String = node.name  {
                switch name {
                case "enemy":
                    handleEnemy(node: node)
                case "bomb":
                    handleBomb(node: node)
                case "overlay":
                    handleOverlay(node: node)
                default:
                    continue
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>?, with event: UIEvent?) {
        activeSliceBG.run(SKAction.fadeOut(withDuration: 0.25))
        activeSliceFG.run(SKAction.fadeOut(withDuration: 0.25))
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        if let touches = touches {
            touchesEnded(touches, with: event)
        }
    }
    
    func redrawActiveSlice() {
        if activeSlicePoints.count < 2 {
            activeSliceBG.path = nil
            activeSliceFG.path = nil
            return
        }
    
        while activeSlicePoints.count > 12 {
            activeSlicePoints.remove(at: 0)
        }

        let path = UIBezierPath()
        path.move(to: activeSlicePoints[0])
        
        for i in 1 ..< activeSlicePoints.count {
            path.addLine(to: activeSlicePoints[i])
        }
        
        activeSliceBG.path = path.cgPath
        activeSliceFG.path = path.cgPath
    }
    
    func playSwooshSound() {
        isSwooshSoundActive = true
        
        let randomNumber = RandomInt(min: 1, max: 3)
        let soundName = "swoosh\(randomNumber).caf"
        
        let swooshSound = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        
        run(swooshSound) { [unowned self] in
            self.isSwooshSoundActive = false
        }
    }
    
    func createEnemy(forceBomb: Bomb = .random) {
        var enemy: SKSpriteNode
        
        var enemyType = RandomInt(min: 0, max: 6)
        // O is a bomb, otherwise normal
    
        if forceBomb == .never {
            enemyType = 1
        } else if forceBomb == .always {
            enemyType = 0
        }
        if enemyType == 0 {
            enemy = SKSpriteNode()
            enemy.zPosition = 1
            enemy.name = "bombContainer"
            
            let bomb = SKSpriteNode(imageNamed: "sliceBomb")
            let emitter = SKEmitterNode(fileNamed: "sliceFuse")!
            
            bomb.name = "bomb"
            bomb.size = CGSize(width: 80, height: 80)
            emitter.position = CGPoint(x: 57, y: 48)
            if iPad {
                bomb.size = CGSize(width: 60, height: 60)
                emitter.position = CGPoint(x: 42.76, y: 36) // CGPoint(x: 76, y: 64)
            }
            enemy.addChild(bomb)
            enemy.addChild(emitter)
            
            if bombSoundEffect != nil {
                bombSoundEffect.stop()
                bombSoundEffect = nil
            }
            
            let path = Bundle.main.path(forResource: "fuse", ofType: ".caf")!
            let url = URL(fileURLWithPath: path)
            let sound = try! AVAudioPlayer(contentsOf: url)
            bombSoundEffect = sound
            sound.play()
            
        } else {
            let idx = RandomInt(min: 1, max: 4)
            enemy = SKSpriteNode(imageNamed: "T\(idx)")
            enemy.name = "enemy"
            enemy.size = CGSize(width: 120, height: 120)
            if iPad {
                enemy.size = CGSize(width: 96, height: 96)
            }
            run(SKAction.playSoundFileNamed("launch.caf", waitForCompletion: false))
            
        }
        
        let w = Int(vw)
        let h = Int(vh)
        // 1
        let randomPosition = CGPoint(x: RandomInt(min: w/8, max: w-w/8), y: -(h/8))
        enemy.position = randomPosition
        
        // 2
        // init x-velocity to normal of range (3,18)
        var randomXVelocity = generator.getX()
        
        // 3
        if randomPosition.x < vw/4.0 {
            randomXVelocity += RandomInt(min: 2, max: 6)
        } else if randomPosition.x < vw/3.0 {
            randomXVelocity += RandomInt(min: 1, max: 3)
        } else if randomPosition.x < (2.0*vw)/3.0 {
            randomXVelocity = -randomXVelocity
        } else {
            randomXVelocity = -randomXVelocity - RandomInt(min: 2, max: 6)
        }
        
        // 4
        let randomYVelocity = generator.getY() + RandomInt(min: -3, max: 3)
        // RandomInt(min: 12, max: 24)
        let randomAngularVelocity = CGFloat(RandomInt(min: -6, max: 6))
        
        print("[ZZ]: Base speed: \(randomXVelocity), \(randomYVelocity), \(randomAngularVelocity)")
        
        // 5
        var speedFactor: CGFloat = 40.0
        if w > 800 {
            speedFactor = 60.0
        }
        let sf = Int(speedFactor)
        var radius: CGFloat = 64
        if iPad {
            radius = 42
        }
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        enemy.physicsBody!.velocity = CGVector(dx: randomXVelocity * sf,
                                               dy: randomYVelocity * sf)
        enemy.physicsBody!.angularVelocity = randomAngularVelocity
        enemy.physicsBody!.collisionBitMask = 0
        
        addChild(enemy)
        activeEnemies.append(enemy)
    }
    
    override func update(_ currentTime: TimeInterval) {
        var bombCount = 0
        if activeEnemies.count > 0 {
            for node in activeEnemies {
                if node.position.y > -140 {
                    continue
                }
                node.removeAllActions()
                guard let name = node.name else { return }
                if ["enemy", "bombContainer"].contains(name) {
                    node.name = ""
                    node.removeFromParent()
                    
                    if let index = activeEnemies.index(of: node) {
                        activeEnemies.remove(at: index)
                    }
                }
                if name == "enemy" {
                    subtractLife()
                } else if name == "bombContainer" {
                    bombCount += 1
                }
            }
        } else {
            if !nextSequenceQueued {
                DispatchQueue.main.asyncAfter(deadline: .now() + popupTime) {
                    [unowned self] in
                    self.tossEnemies()
                }
                nextSequenceQueued = true
            }
        }
        
        if bombCount == 0 {
            // no bombs – stop the fuse sound!
            if bombSoundEffect != nil {
                bombSoundEffect.stop()
                bombSoundEffect = nil
            }
        }
    }
    
    func tossEnemies() {
        if gameEnded {
            return
        }
        
        popupTime *= 0.991
        chainDelay *= 0.99
        gameSpeed *= 1.02
        
        let sequenceType = sequence[sequencePosition]
        
        switch sequenceType {
        case .oneNoBomb:
            createEnemy(forceBomb: .never)
            
        case .one:
            createEnemy()
            
        case .twoWithOneBomb:
            createEnemy(forceBomb: .never)
            createEnemy(forceBomb: .always)
            
        case .two:
            createEnemy()
            createEnemy()
            
        case .three:
            createEnemy()
            createEnemy()
            createEnemy()
            
        case .four:
            createEnemy()
            createEnemy()
            createEnemy()
            createEnemy()
            
        case .chain:
            createEnemy()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0)) { [unowned self] in self.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0 * 2)) { [unowned self] in self.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0 * 3)) { [unowned self] in self.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0 * 4)) { [unowned self] in self.createEnemy() }
            
        case .fastChain:
            
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0)) { [unowned self] in self.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0 * 2)) { [unowned self] in self.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0 * 3)) { [unowned self] in self.createEnemy() }
            DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0 * 4)) { [unowned self] in self.createEnemy() }
        }
        
        sequencePosition += 1
        nextSequenceQueued = false
        
        if sequencePosition % 5 == 0 {
            showWaveNumber()
        }
        if sequencePosition % 15 == 0 {
            let sound = getRandomSound()
            run(SKAction.playSoundFileNamed("\(sound)", waitForCompletion: false))
        }

    }
    
    func subtractLife() {
        lives -= 1
        
        run(SKAction.playSoundFileNamed("trump_wrong", waitForCompletion: false))
        
        var life: SKSpriteNode
        
        if lives == 2 {
            life = livesImages[0]
        } else if lives == 1 {
            life = livesImages[1]
        } else {
            life = livesImages[2]
            endGame(triggeredByBomb: false)
        }
        
        life.texture = SKTexture(imageNamed: "sliceLifeGone")
        life.xScale = 1.3
        life.yScale = 1.3
        life.run(SKAction.scale(to: 1, duration:0.1))
    }
    
    func endGame(triggeredByBomb: Bool) {
        if gameEnded {
            return
        }
        
        gameEnded = true
        showLoss()
        physicsWorld.speed = 0
        isUserInteractionEnabled = false
        
        if bombSoundEffect != nil {
            bombSoundEffect.stop()
            bombSoundEffect = nil
        }
        
        if triggeredByBomb {
            run(SKAction.playSoundFileNamed("fired.caf", waitForCompletion: false))
            livesImages[0].texture = SKTexture(imageNamed: "sliceLifeGone")
            livesImages[1].texture = SKTexture(imageNamed: "sliceLifeGone")
            livesImages[2].texture = SKTexture(imageNamed: "sliceLifeGone")
        }
        prefs.set(max(score, bestScore), forKey: "best")

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [unowned self] in
            self.resetWorld()
            self.isUserInteractionEnabled = true
            self.resetScene()
        }
        
    }
}
