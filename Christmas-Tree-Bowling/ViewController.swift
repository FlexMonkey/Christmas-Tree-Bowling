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
    
    lazy var sceneKitView:SCNView =
    {
        let scene = SCNScene()
        let view = SCNView()
        
        view.backgroundColor = UIColor.blackColor()
        view.scene = scene
        
        view.allowsCameraControl = true // !!!!!!
        
        view.showsStatistics = true
        
        return view
    }()
    
    var scene: SCNScene
        {
            return sceneKitView.scene!
    }
    
    var physicsBodyBox: SCNPhysicsBody!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.addSubview(sceneKitView)
        
        physicsBodyBox = setupSceneKit()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
    {
        physicsBodyBox.applyForce(SCNVector3(0, 0, -40), impulse: true)
    }
    
    func setupSceneKit() -> SCNPhysicsBody
    {
        // Camera
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 7)
        
        scene.rootNode.addChildNode(cameraNode)
        
        // Omni light
        
        for lightPosition in [SCNVector3(-10, 0, 10), SCNVector3(10, 10, -10)]
        {
            let light = SCNLight()
            light.type =  SCNLightTypeOmni
            
            let lightNode = SCNNode()
            lightNode.light = light
            
            lightNode.position = lightPosition
            
            scene.rootNode.addChildNode(lightNode)
        }
        
        // Cylinders
        
        for z in 0 ... 6
        {
            for x in 0 ... z
            {
                let cone = SCNCone(topRadius: 0, bottomRadius: 0.5, height: 1.5)
                let trunk = SCNCylinder(radius: 0.25, height: 0.5)
                
                let coneNode = SCNNode(geometry: cone)
                let trunkNode = SCNNode(geometry: trunk)
                
                coneNode.position = SCNVector3(0, 0.5, 0)
                trunkNode.position = SCNVector3(0, -0.5, 0)
                
                let foo = SCNNode()
                foo.addChildNode(coneNode)
                foo.addChildNode(trunkNode)
                
                let cylinderNode = foo.flattenedClone()
                
                cylinderNode.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.Dynamic,
                    shape: SCNPhysicsShape(geometry: cylinderNode.geometry!, options: nil))
                
                let spacing = Float(2.5)
                
                cylinderNode.position = SCNVector3((-spacing * Float(z) / 2) + (Float(x) * spacing),
                    -1,
                    -Float(z) * spacing)
                
                scene.rootNode.addChildNode(cylinderNode)
            }
        }
        
        // Box
        
        let boxNode = SCNNode(geometry: SCNSphere(radius: 0.25))
        boxNode.position = SCNVector3(0, 0, 5)
        boxNode.rotation = SCNVector4(0.2, 0.3, 0.4, 1)
        
        scene.rootNode.addChildNode(boxNode)
        
        // Floor
        
        let floor = SCNFloor()
        floor.reflectivity = 0
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(0, -1, 0)
        
        scene.rootNode.addChildNode(floorNode)
        
        // Physics for box
        
        let physicsBodyBox = SCNPhysicsBody(type: SCNPhysicsBodyType.Dynamic,
            shape: SCNPhysicsShape(geometry: boxNode.geometry!, options: nil))
        
        boxNode.physicsBody = physicsBodyBox
        
        // Physics for floor
        
        let physicsBodyFloor = SCNPhysicsBody(type: SCNPhysicsBodyType.Static,
            shape: SCNPhysicsShape(geometry: floorNode.geometry!, options: nil))
        
        floorNode.physicsBody = physicsBodyFloor
        
        // ---
        
        return physicsBodyBox
    }
    
    override func viewDidLayoutSubviews()
    {
        sceneKitView.frame = view.bounds
    }
    
}
