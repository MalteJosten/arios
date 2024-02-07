import Foundation
import ARKit
import Network

/**
    UIViewController which contains AR-Session and corresponding features (such as Image Recognition).
 */

class ARHandler : UIViewController, ARSCNViewDelegate {
    
    // Configuration used for the session.
    var configuration: ARImageTrackingConfiguration?
    
    var handler: DeviceHandler
    
    // Used to identify last tracked image
    var currentARImageIdentifier: UUID?
    var currentARAnchor: ARAnchor?
    
    var arView: ARSCNView {
        return self.view as! ARSCNView
    }
    
    init(tHandler: DeviceHandler) {
        self.handler = tHandler
        super.init(nibName: nil, bundle: nil)
        self.handler.setARHandler(handler: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = ARSCNView(frame: .zero)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arView.delegate = self
        arView.scene = SCNScene()
    }
    
    // MARK: - AR View Handling
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    // Configuring session
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Setting the configuration to track images.
        self.configuration = ARImageTrackingConfiguration()
        
        // Loading library containing the images to track.
        if let imagesToTrack = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main) {
            self.configuration!.trackingImages = imagesToTrack
        }
        
        // Starting AR session
        arView.session.run(self.configuration!)
        arView.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
    // Gets called whenever a image is detected/tracked.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        
        // Retrieving anchor of detected/tracked image.
        self.currentARAnchor = anchor
        
        // Cast found anchor as image anchor.
        guard let imageAnchor = anchor as? ARImageAnchor else { return nil }
        
        // Get the name of the image from the anchor.
        guard let imageName = imageAnchor.name else { return nil }
        
        // Starting Service Discovery for tracked image (name).
        self.handler.startBonjour(imageName: imageName)
        
        return node
    }
    
    // Resetting UUID to reset Image Recognition, so we can scan a marker multiple times.
    func resetUUID() {
        DispatchQueue.main.async {
            self.currentARAnchor = nil
            self.arView.session.run(self.configuration!, options: [.removeExistingAnchors, .resetTracking])
        }
    }

    func sessionWasInterrupted(_ session: ARSession) {}
    func sessionInterruptionEnded(_ session: ARSession) {}
    func session(_ session: ARSession, didFailWithError error: Error) {}
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {}
}
