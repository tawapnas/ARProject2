//
//  ViewController.swift
//  ARProject2
//
//  Created by สรรพวัศ ซิ่วสุวรรณ on 17/11/2561 BE.
//  Copyright © 2561 สรรพวัศ ซิ่วสุวรรณ. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

enum bodyType : Int{
    
    case box = 1
    case earth = 2
    
}

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var score: UILabel!
    @IBOutlet weak var crashed: UILabel!
    
    var lastNode: SCNNode?
    var player: SCNNode?
    var currentTransform: float3 = [0,0,0]
    var timer = Timer()
    var count = 0
    var crashedTime = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
       
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.scene.physicsWorld.contactDelegate = self
    
        let earthShape = SCNSphere(radius: 0.1)
        let earthNode = SCNNode(geometry: earthShape)
        let body = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: earthNode))
        earthNode.physicsBody = body
        earthNode.physicsBody?.restitution = 1
        
        earthNode.physicsBody?.categoryBitMask = bodyType.earth.rawValue
        earthNode.physicsBody?.collisionBitMask = bodyType.box.rawValue
        earthNode.physicsBody?.contactTestBitMask = bodyType.box.rawValue
        
        earthNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        
        earthNode.position = SCNVector3(0, 0, 0)
        
        player=earthNode
        sceneView.scene.rootNode.addChildNode(earthNode)
        
        registerGestureRecognizers()
        runtime()
    }
    
    func runtime(){
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(counting), userInfo: nil, repeats: true)
    }
    
    @objc func counting(){
        let posX = Double.random(in: -5.00...5.00)
        let posY = Double.random(in: -1.00...2.00)
        let posZ = Double.random(in: -5.00 ... -2.00)
        addBox(posX: Float(posX), posY: Float(posY), posZ: Float(posZ))
    }
    
    func addBox(posX: Float,posY: Float,posZ: Float){
        /*let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let boxNode = SCNNode(geometry: box)*/
        
        let cockRoachScene = SCNScene(named: "art.scnassets/Mesh_Cockroach.scn")!
        let cockRoach = cockRoachScene.rootNode.childNode(withName: "cockroach", recursively: true)
        
        cockRoach?.position = SCNVector3(posX, posY, posZ)
        lastNode = cockRoach
        
        let body = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: cockRoach!))
        cockRoach?.physicsBody = body
        cockRoach?.physicsBody?.restitution = 1
        
        //Set category for this node
        cockRoach?.physicsBody?.categoryBitMask = bodyType.box.rawValue
        //Set which categories can contact with this node
        //Can omit this line when you want to trigger invisible things, it'll go through.
        cockRoach?.physicsBody?.collisionBitMask = bodyType.box.rawValue
        // [OPTIONAL] Like a listener
        cockRoach?.physicsBody?.contactTestBitMask = bodyType.box.rawValue
        
        self.sceneView.scene.rootNode.addChildNode(cockRoach!)
        
        let fireEmitter = createFire()
        cockRoach?.addParticleSystem(fireEmitter)
        
        let translate = SCNAction.move(to: SCNVector3(0, 0, 0), duration: 6.0)
        cockRoach?.look(at: SCNVector3(0, 0, 0))
        cockRoach?.runAction(translate)
    }
    
    func registerGestureRecognizers(){
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipeGestureRecognizer.direction = UISwipeGestureRecognizer.Direction.left
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        self.sceneView.addGestureRecognizer(swipeGestureRecognizer)
    }
    
    @objc func swiped(recognizer: UISwipeGestureRecognizer){
        switch recognizer.direction.rawValue {
        case 2:
            print("Swiped Left!")
            /*let rotate = SCNAction.rotateBy(x: 0, y: -10, z: 0, duration: 5.0)
            let repeatForever = SCNAction.repeatForever(rotate)
            lastNode?.runAction(repeatForever)
            
            let translate = SCNAction.move(to: SCNVector3(currentTransform.x, currentTransform.y, currentTransform.z), duration: 3.0)
            lastNode?.runAction(translate)*/
        default:
            break
        }
    }
    
    @objc func tapped(recognizer: UITapGestureRecognizer){
        //let touchLocation = recognizer.location(in: sceneView)
        let centerPoint = CGPoint(x: UIScreen.main.bounds.width * 0.5, y: UIScreen.main.bounds.height * 0.5)
        print(centerPoint)
        let hitResults = sceneView.hitTest(centerPoint)
        if let hitResultsWithFeaturePoint = hitResults.first?.node{
            if(hitResultsWithFeaturePoint.physicsBody?.categoryBitMask == bodyType.box.rawValue){
                hitResultsWithFeaturePoint.removeFromParentNode()
                count+=1
                print(count)
                score.text = "Score: \(count)"
                /*let translation = hitResultsWithFeaturePoint.worldTransform.translation
                 addBox(posX: translation.x, posY: translation.y, posZ: translation.z)*/
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        currentTransform = frame.camera.transform.translation
    }
    
    /*func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        print("Detected")
        let node = SCNNode()
        if let imageAnchor = anchor as? ARImageAnchor{
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            plane.firstMaterial?.diffuse.contents = UIColor.blue
            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi/2
            
            node.addChildNode(planeNode)
        }
        return node
    }*/
    
    func createFire() -> SCNParticleSystem{
        let fire = SCNParticleSystem(named: "Fire", inDirectory: nil)
        return fire!
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        if (contact.nodeA.physicsBody?.categoryBitMask == bodyType.box.rawValue && contact.nodeB.physicsBody?.categoryBitMask == bodyType.earth.rawValue){
            
            print("Crashed B is Earth")
            contact.nodeA.removeFromParentNode()
            crashedTime+=1
            crashed.text = "Crashed: \(crashedTime)"
        }
        else if(contact.nodeA.physicsBody?.categoryBitMask == bodyType.earth.rawValue && contact.nodeB.physicsBody?.categoryBitMask == bodyType.box.rawValue){
            
            print("Crashed A is Earth ")
            contact.nodeB.removeFromParentNode()
            crashedTime+=1
            crashed.text = "Crashed: \(crashedTime)"
        }
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
    
}

extension float4x4{
    var translation: float3{
        let translation = self.columns.3
        return float3(translation.x,translation.y,translation.z)
    }
}
