//
//  ViewController.swift
//  Christmas-Tree-Bowling
//
//  Created by Simon Gladman on 15/12/2015.
//  Copyright © 2015 Simon Gladman. All rights reserved.
//


import UIKit
import SceneKit

class ViewController: UIViewController
{
    let halfPi = CGFloat(M_PI_2)
    let velocity = CGFloat(30)
    
    lazy var resetButton: UIButton =
    {
        let button = UIButton()
        
        button.setTitle("Reset", forState: UIControlState.Normal)
        button.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Highlighted)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        button.layer.borderColor = UIColor.whiteColor().CGColor
        button.layer.cornerRadius = 4
        button.layer.borderWidth = 1
        
        return button
    }()
    
    lazy var sceneKitView: SCNView =
    {
        let scene = SCNScene()
        let view = SCNView()
        view.backgroundColor = UIColor.blackColor()
        view.scene = scene
     
        scene.physicsWorld.contactDelegate = self
        
        view.showsStatistics = true
        
        return view
    }()
    
    lazy var christmasTreeCompositeNode: SCNNode =
    {
        let cone = SCNCone(topRadius: 0, bottomRadius: 0.5, height: 1.5)
        let trunk = SCNCylinder(radius: 0.25, height: 0.5)
        let bauble = SCNSphere(radius: 0.1)
        
        let coneNode = SCNNode(geometry: cone)
        let trunkNode = SCNNode(geometry: trunk)
        let baubleNode = SCNNode(geometry: bauble)
        
        coneNode.position = SCNVector3(0, 0.5, 0)
        trunkNode.position = SCNVector3(0, -0.5, 0)
        baubleNode.position = SCNVector3(0, 1.2, 0)
        
        let coneMaterial = SCNMaterial()
        coneMaterial.diffuse.contents = UIColor.greenColor()
        cone.materials = [coneMaterial]
        
        let trunkMaterial = SCNMaterial()
        trunkMaterial.diffuse.contents = UIColor.brownColor()
        trunk.materials = [trunkMaterial]
        
        let baubleMaterial = SCNMaterial()
        baubleMaterial.reflective.contents = UIImage(named: "reflection.jpg")
        baubleMaterial.reflective.intensity = 0.5
        baubleMaterial.diffuse.contents = UIColor(red: 1, green: 0.75, blue: 9.75, alpha: 1)
        baubleMaterial.shininess = 0.5
        baubleMaterial.specular.contents = UIColor.whiteColor()
        bauble.materials = [baubleMaterial]
        
        let christmasTreeCompositeNode = SCNNode()
        christmasTreeCompositeNode.addChildNode(coneNode)
        christmasTreeCompositeNode.addChildNode(trunkNode)
        christmasTreeCompositeNode.addChildNode(baubleNode)
        
        return christmasTreeCompositeNode
    }()
    
    var scene: SCNScene
    {
        return sceneKitView.scene!
    }
    
    let touchCatchingPlaneNode = SCNNode(geometry: SCNPlane(width: 20, height: 20))
    let ballNode = SCNNode(geometry: SCNSphere(radius: 0.25))
    let pointerNode = SCNNode(geometry: SCNCone(topRadius: 0.1, bottomRadius: 0, height: 0.4))
    
    let conductor = Conductor()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.addSubview(sceneKitView)
        view.addSubview(resetButton)
        
        resetButton.addTarget(self, action: "resetTrees", forControlEvents: UIControlEvents.TouchDown)
        
        setupSceneKit()
    }
    
    // MARK: Touch handling
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        guard let touch = touches.first where touch.type == UITouchType.Stylus else
        {
            return
        }
        
        ballNode.physicsBody = nil
        ballNode.hidden = false
        
        pointerNode.hidden = false
        
        positionBallFromTouch(touch)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        guard let touch = touches.first where touch.type == UITouchType.Stylus else
        {
            return
        }
        
        positionBallFromTouch(touch)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        guard let touch = touches.first where touch.type == UITouchType.Stylus else
        {
            return
        }
        
        let physicsBodyBall = SCNPhysicsBody(type: SCNPhysicsBodyType.Dynamic,
            shape: SCNPhysicsShape(geometry: ballNode.geometry!, options: nil))
        
        ballNode.physicsBody = physicsBodyBall
        ballNode.physicsBody?.categoryBitMask = 1
        
        let altitude = ((halfPi - touch.altitudeAngle) / halfPi)
        
        let xx = -touch.azimuthUnitVectorInView(view).dx * altitude
        let yy = touch.azimuthUnitVectorInView(view).dy * altitude
        let zz = 1 - sqrt(xx * xx + yy * yy)
       
        let direction = SCNVector3(xx * velocity,
            yy * velocity,
            zz * -velocity)
    
        physicsBodyBall.applyForce(direction, impulse: true)
        physicsBodyBall.contactTestBitMask = 2
        
        pointerNode.hidden = true
    }
    
    func positionBallFromTouch(touch: UITouch)
    {
        guard let hitTestResult:SCNHitTestResult = sceneKitView.hitTest(touch.locationInView(view),
            options: nil)
            .filter( { $0.node == touchCatchingPlaneNode }).first else
        {
            return
        }
       
        pointerNode.position = SCNVector3(hitTestResult.localCoordinates.x, hitTestResult.localCoordinates.y, 5)
        pointerNode.eulerAngles = SCNVector3(touch.altitudeAngle, 0.0, 0 - touch.azimuthAngleInView(view) - halfPi)
        
        ballNode.position = SCNVector3(hitTestResult.localCoordinates.x,
            hitTestResult.localCoordinates.y,
            5)
    }
  
    func resetTrees()
    {
        trees.forEach{ $0.removeFromParentNode() }
        
        let spacing = Float(2.5)
        
        for z in 0 ... 4
        {
            for x in 0 ... z
            {
                let christmasTreeeNode = christmasTreeCompositeNode.flattenedClone()
                
                christmasTreeeNode.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.Dynamic,
                    shape: SCNPhysicsShape(geometry: christmasTreeeNode.geometry!, options: nil))
                
                christmasTreeeNode.physicsBody?.categoryBitMask = 1
                christmasTreeeNode.physicsBody?.contactTestBitMask = 1
                
                christmasTreeeNode.position = SCNVector3((-spacing * Float(z) / 2) + (Float(x) * spacing),
                    -1,
                    -Float(z) * spacing)
                
                scene.rootNode.addChildNode(christmasTreeeNode)
                
                trees.append(christmasTreeeNode)
            }
        }
    }
    
    var trees = [SCNNode]()
    
    
    // MARK: SceneKit set up
    
    func setupSceneKit()
    {
        // Camera
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 7)
        
        scene.rootNode.addChildNode(cameraNode)
        
        // Lights
        
        let centreNode = SCNNode()
        centreNode.position = SCNVector3(x: 0, y: 1, z: -2)
        scene.rootNode.addChildNode(centreNode)
        
        for lightPosition in [SCNVector3(-10, 5, 10), SCNVector3(10, 5, 10)]
        {
            let light = SCNLight()
            light.type =  SCNLightTypeDirectional
            light.castsShadow = false
            light.shadowSampleCount = 3
            
            let lightNode = SCNNode()
            lightNode.light = light
            
            let constraint = SCNLookAtConstraint(target: centreNode)
            lightNode.constraints = [constraint]
            
            lightNode.position = lightPosition
            
            scene.rootNode.addChildNode(lightNode)
        }
        
        // Christmas Trees
        resetTrees()

        
        // Ball
        ballNode.position = SCNVector3(0, 0, 5)
        ballNode.rotation = SCNVector4(0.2, 0.3, 0.4, 1)
        ballNode.hidden = true
        
        let ballMaterial = SCNMaterial()
        ballMaterial.diffuse.contents = UIColor.blueColor()
        ballMaterial.specular.contents = UIColor.whiteColor()
        ballMaterial.reflective.contents = UIImage(named: "winterNight.jpg")
        ballMaterial.reflective.intensity = 0.4
        ballMaterial.shininess = 0.9
        
        ballNode.geometry!.materials = [ballMaterial]
        
        scene.rootNode.addChildNode(ballNode)

        // Pointer
        
        pointerNode.hidden = true
        pointerNode.opacity = 0.75
        pointerNode.pivot = SCNMatrix4MakeTranslation(0, -0.45, 0)
        
        scene.rootNode.addChildNode(pointerNode)
        
        // Floor
        
        let floorMaterial = SCNMaterial()
        floorMaterial.normal.contents = UIImage(named: "bumpMap.jpg")
        floorMaterial.normal.wrapS = SCNWrapMode.Repeat
        floorMaterial.normal.wrapT = SCNWrapMode.Repeat
        floorMaterial.normal.contentsTransform = SCNMatrix4MakeScale(25, 25, 1)
        floorMaterial.normal.intensity = 0.25
        
        floorMaterial.selfIllumination.contents = UIColor.whiteColor()
        floorMaterial.selfIllumination.intensity = 0.25
        
        floorMaterial.diffuse.contents = UIColor(red: 0.95, green: 0.95, blue: 1, alpha: 1)
        floorMaterial.ambient.contents = UIColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 1)
        floorMaterial.specular.contents = UIColor.whiteColor()
   
        let floor = SCNFloor()
      
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(0, -1, 0)
        
        floor.materials = [floorMaterial]
        floor.reflectivity = 0.75
        floor.reflectionResolutionScaleFactor = 1
        
        scene.rootNode.addChildNode(floorNode)
      
        let physicsBodyFloor = SCNPhysicsBody(type: SCNPhysicsBodyType.Static,
            shape: SCNPhysicsShape(geometry: floorNode.geometry!, options: nil))
        
        floorNode.physicsBody = physicsBodyFloor
        
        // Touch catching plane
        
        touchCatchingPlaneNode.opacity = 0.000001
        touchCatchingPlaneNode.castsShadow = false
        scene.rootNode.addChildNode(touchCatchingPlaneNode)
        touchCatchingPlaneNode.position = ballNode.position
        
        // Snow

        let snowPlane = SCNPlane(width: 10, height: 5)
        let snowNode = SCNNode(geometry: snowPlane)

        snowNode.position = SCNVector3(0, 7, 0)
        snowNode.eulerAngles = SCNVector3(Float(M_PI_2), Float(0.0), Float(0.0))
        
        let field = SCNPhysicsField.noiseFieldWithSmoothness(1, animationSpeed: 0.1)
        field.falloffExponent = 0
        field.strength = 0.5
        
        snowNode.physicsField = field
        
         field.categoryBitMask = 2
        snowNode.categoryBitMask = 2
        
        scene.rootNode.addChildNode(snowNode)
        
        let snowParticleSystem = SCNParticleSystem()
        snowParticleSystem.birthRate = 750
        snowParticleSystem.particleLifeSpan = 10
        snowParticleSystem.particleDiesOnCollision = true
        snowParticleSystem.colliderNodes = [floorNode]
        snowParticleSystem.warmupDuration = 10
        snowParticleSystem.affectedByGravity = false
        snowParticleSystem.acceleration = SCNVector3(0, -0.25, 0)
        
        snowParticleSystem.emitterShape = snowNode.geometry!

        snowParticleSystem.particleSize = 0.008
        
        snowNode.addParticleSystem(snowParticleSystem)

        snowParticleSystem.affectedByPhysicsFields = true
    }
    
    // MARK: Layout
    
    override func viewDidLayoutSubviews()
    {
        sceneKitView.frame = view.bounds
        
        resetButton.frame = CGRect(origin: CGPointZero,
            size: resetButton.intrinsicContentSize())
    }
    
    override func prefersStatusBarHidden() -> Bool
    {
        return true
    }
}

// MARK: SCNPhysicsContactDelegate

extension ViewController: SCNPhysicsContactDelegate
{
    func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact)
    {
        print(contact.collisionImpulse)
        
        if contact.nodeA.physicsBody?.contactTestBitMask == 1 && contact.nodeB.physicsBody?.contactTestBitMask != 2
        {
            conductor.play(frequency: 440, amplitude: 0.025,  playMetalBar: false)
        }
        
        
        if (contact.nodeA.physicsBody?.contactTestBitMask == 2 && contact.nodeB.physicsBody?.contactTestBitMask == 1) ||
            (contact.nodeA.physicsBody?.contactTestBitMask == 1 && contact.nodeB.physicsBody?.contactTestBitMask == 2)
        {
            conductor.play(frequency: 440, amplitude: 0.05,  playMetalBar: true)
        }
    }
  
}

// Instrument

class Sleighbells: AKInstrument
{
    override init()
    {
        super.init()
        
        let note = BarNote()
        addNoteProperty(note.frequency)
        addNoteProperty(note.amplitude)
        
        let instrument = AKSleighbells.presetSoftBells()

        setAudioOutput(instrument)
    }
}

class MetalBar: AKInstrument
{
    override init()
    {
        super.init()
        
        let note = BarNote()
        addNoteProperty(note.frequency)
        addNoteProperty(note.amplitude)
        
        let instrument = AKStruckMetalBar.presetSmallHollowMetalBar()
        
        setAudioOutput(instrument)
    }
}

class Conductor
{
    let sleighbells = Sleighbells()
    let metalBar = MetalBar()
    
    init()
    {
        AKOrchestra.addInstrument(metalBar)
        AKOrchestra.addInstrument(sleighbells)
    }
    
    func play(frequency frequency: Float, amplitude: Float, playMetalBar: Bool)
    {
        let barNote = BarNote(frequency: frequency, amplitude: amplitude)
        barNote.duration.value = 1.0
        
        if playMetalBar
        {
           metalBar.playNote(barNote)
        }
        else
        {
            sleighbells.playNote(barNote)
        }
    }
}

class BarNote: AKNote
{
    var frequency = AKNoteProperty(value: 0,    minimum: 0, maximum: 1000)
    var amplitude = AKNoteProperty(value: 0.04, minimum: 0, maximum: 0.25)
    
    override init() {
        super.init()
        addProperty(frequency)
        addProperty(amplitude)
    }
    
    convenience init(frequency: Float, amplitude: Float) {
        self.init()
        self.frequency.value = frequency
        self.amplitude.value = amplitude
    }
}


