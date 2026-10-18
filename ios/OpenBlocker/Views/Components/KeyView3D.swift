// The hero key: our puck (KeyModel.usdz) rendered in SceneKit with a matte
// soft-touch material, a soft studio light from the top left, an idle spin,
// and a darker fill that rises across the face in screen space while you hold.

import SwiftUI
import SceneKit
import SceneKit.ModelIO
import simd
import UIKit

struct KeyView3D: View {
    var progress: Double
    var yaw: Float
    var isDragging: Bool
    var reduceMotion: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                // Soft contact shadow, thrown a little to the bottom right.
                Ellipse()
                    .fill(Color.black.opacity(colorScheme == .dark ? 0.6 : 0.2))
                    .frame(width: side * 0.6, height: side * 0.11)
                    .blur(radius: side * 0.05)
                    .offset(x: side * 0.04, y: side * 0.3)
                
                SceneKitKeyView(
                    yaw: yaw,
                    animatesYaw: !isDragging,
                    fillLevel: FillLevel.shaderLevel(for: progress),
                    spins: !reduceMotion
                )
                .frame(width: side, height: side)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct SceneKitKeyView: UIViewRepresentable {
    var yaw: Float
    var animatesYaw: Bool
    var fillLevel: Float
    var spins: Bool
    
    private static let spinKey = "idleSpin"
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X
        view.clipsToBounds = false
        view.isPlaying = true
        view.isUserInteractionEnabled = false
        
        let scene = SCNScene()
        scene.background.contents = UIColor.clear
        scene.lightingEnvironment.contents = Self.studioEnvironment()
        scene.lightingEnvironment.intensity = KeyPalette.environmentIntensity
        
        // pivot = drag yaw, spinner = idle spin, model inside.
        let pivot = SCNNode()
        let spinner = SCNNode()
        pivot.addChildNode(spinner)
        if !Self.loadModel(into: spinner) {
            spinner.addChildNode(Self.fallbackPuck())
        }
        Self.applyMaterials(to: spinner)
        let materials = Self.collectMaterials(from: spinner)
        Self.installFillShader(on: materials)
        scene.rootNode.addChildNode(pivot)
        
        // Key light from the top left, a weak fill from the right.
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .directional
        keyLight.light?.intensity = 700
        keyLight.eulerAngles = SCNVector3(-0.95, -0.7, 0)
        scene.rootNode.addChildNode(keyLight)
        
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .directional
        fillLight.light?.intensity = 160
        fillLight.eulerAngles = SCNVector3(-0.4, 0.9, 0)
        scene.rootNode.addChildNode(fillLight)
        
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.automaticallyAdjustsZRange = true
        camera.camera?.wantsHDR = false
        scene.rootNode.addChildNode(camera)
        Self.frameCamera(camera, around: pivot)
        
        // Screen-space extent of the puck so the fill runs bottom to top of the view.
        let (minY, maxY) = Self.viewSpaceYExtent(of: spinner, camera: camera)
        for material in materials {
            material.setValue(NSNumber(value: minY), forKey: "fillMinY")
            material.setValue(NSNumber(value: maxY), forKey: "fillMaxY")
        }
        
        context.coordinator.pivot = pivot
        context.coordinator.spinner = spinner
        context.coordinator.materials = materials
        
        view.scene = scene
        view.pointOfView = camera
        return view
    }
    
    func updateUIView(_ view: SCNView, context: Context) {
        let coordinator = context.coordinator
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = animatesYaw ? 0.9 : 0
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        coordinator.pivot?.eulerAngles.y = yaw
        SCNTransaction.commit()
        
        if let spinner = coordinator.spinner {
            let spinning = spinner.action(forKey: Self.spinKey) != nil
            if spins && !spinning {
                let turn = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 30)
                spinner.runAction(.repeatForever(turn), forKey: Self.spinKey)
            } else if !spins && spinning {
                spinner.removeAction(forKey: Self.spinKey)
            }
        }
        
        for material in coordinator.materials {
            material.setValue(NSNumber(value: fillLevel), forKey: "fillLevel")
        }
    }
    
    // MARK: Model
    
    private static func loadModel(into node: SCNNode) -> Bool {
        guard let url = Bundle.main.url(forResource: "KeyModel", withExtension: "usdz"),
              let model = try? SCNScene(url: url, options: nil) else {
            return false
        }
        for child in model.rootNode.childNodes {
            node.addChildNode(child.clone())
        }
        return !node.childNodes.isEmpty
    }
    
    private static func fallbackPuck() -> SCNNode {
        let cylinder = SCNCylinder(radius: 0.5, height: 0.2)
        return SCNNode(geometry: cylinder)
    }
    
    private static func applyMaterials(to node: SCNNode) {
        node.castsShadow = false
        if var geometry = node.geometry {
            geometry.wantsAdaptiveSubdivision = false
            let mesh = MDLMesh(scnGeometry: geometry)
            mesh.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 0.85)
            geometry = SCNGeometry(mdlMesh: mesh)
            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.diffuse.contents = KeyPalette.body
            // Matte soft-touch: very rough, no clear coat.
            material.roughness.contents = NSNumber(value: 0.82)
            material.metalness.contents = NSNumber(value: 0.0)
            geometry.materials = [material]
            node.geometry = geometry
        }
        node.childNodes.forEach(applyMaterials)
    }
    
    private static func collectMaterials(from node: SCNNode) -> [SCNMaterial] {
        (node.geometry?.materials ?? []) + node.childNodes.flatMap(collectMaterials)
    }
    
    // MARK: Fill shader
    
    /// The fill rises in view space (screen up), so it stays level while the
    /// puck spins. A hairline of shade marks the edge; no slosh, it is a
    /// calm, linear rise.
    static let fillSurfaceShader = """
    #pragma arguments
    float fillLevel;
    float fillMinY;
    float fillMaxY;
    float4 fillColor;
    #pragma body
    float span = max(fillMaxY - fillMinY, 0.0001);
    float t = (_surface.position.y - fillMinY) / span;
    float dry = smoothstep(fillLevel - 0.004, fillLevel + 0.004, t);
    float edge = (1.0 - smoothstep(0.0, 0.012, abs(t - fillLevel))) * step(0.0, fillLevel) * step(fillLevel, 1.0);
    _surface.diffuse.rgb = mix(fillColor.rgb, _surface.diffuse.rgb, dry);
    _surface.diffuse.rgb *= 1.0 - 0.12 * edge;
    """
    
    private static func installFillShader(on materials: [SCNMaterial]) {
        for material in materials {
            material.shaderModifiers = [.surface: fillSurfaceShader]
            material.setValue(NSNumber(value: FillLevel.hidden), forKey: "fillLevel")
            material.setValue(NSNumber(value: Float(-0.5)), forKey: "fillMinY")
            material.setValue(NSNumber(value: Float(0.5)), forKey: "fillMaxY")
            material.setValue(KeyPalette.fill, forKey: "fillColor")
        }
    }
    
    // MARK: Lighting
    
    /// Small studio HDRI stand-in: bright softbox above, warm floor below.
    private static func studioEnvironment() -> UIImage {
        let size = CGSize(width: 512, height: 256)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let cg = ctx.cgContext
            let colors = [
                UIColor(white: 0.98, alpha: 1).cgColor,
                UIColor(white: 0.80, alpha: 1).cgColor,
                UIColor(red: 0.52, green: 0.50, blue: 0.47, alpha: 1).cgColor,
                UIColor(red: 0.28, green: 0.27, blue: 0.26, alpha: 1).cgColor
            ] as CFArray
            let stops: [CGFloat] = [0, 0.38, 0.55, 1]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: stops) {
                cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            }
            UIColor.white.setFill()
            cg.fill(CGRect(x: 120, y: 20, width: 140, height: 46))
            UIColor(white: 1, alpha: 0.6).setFill()
            cg.fill(CGRect(x: 360, y: 40, width: 60, height: 30))
        }
    }
    
    // MARK: Camera
    
    private static func frameCamera(_ camera: SCNNode, around node: SCNNode) {
        let (minB, maxB) = node.boundingBox
        let center = simd_float3((minB.x + maxB.x) / 2, (minB.y + maxB.y) / 2, (minB.z + maxB.z) / 2)
        let radius = max(maxB.x - minB.x, maxB.z - minB.z) / 2
        let fov: Float = 26
        camera.camera?.fieldOfView = CGFloat(fov)
        let elevation: Float = 50 * .pi / 180
        let direction = simd_normalize(simd_float3(0, sin(elevation), cos(elevation)))
        let distance = max(radius, 0.1) / tan(fov * .pi / 180 * 0.5 * 0.78)
        camera.simdPosition = center + direction * distance
        camera.look(at: SCNVector3(center.x, center.y, center.z), up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1))
    }
    
    private static func viewSpaceYExtent(of node: SCNNode, camera: SCNNode) -> (Float, Float) {
        let (minB, maxB) = node.boundingBox
        var lo = Float.greatestFiniteMagnitude
        var hi = -Float.greatestFiniteMagnitude
        for x in [minB.x, maxB.x] {
            for y in [minB.y, maxB.y] {
                for z in [minB.z, maxB.z] {
                    let p = node.convertPosition(SCNVector3(x, y, z), to: camera)
                    lo = min(lo, p.y)
                    hi = max(hi, p.y)
                }
            }
        }
        // A round puck's real silhouette is inside its bounding box corners.
        let inset = (hi - lo) * 0.06
        return (lo + inset, hi - inset)
    }
    
    final class Coordinator {
        var pivot: SCNNode?
        var spinner: SCNNode?
        var materials: [SCNMaterial] = []
    }
}
