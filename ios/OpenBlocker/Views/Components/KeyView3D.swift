// 3D key view using SceneKit with the real CAD model

import SwiftUI
import SceneKit
import SceneKit.ModelIO
import simd

struct KeyView3D: View, Animatable {
    var progress: CGFloat
    @Environment(\.colorScheme) private var colorScheme
    @State private var rotationAngle: Float = 0
    @State private var pressScale: CGFloat = 1.0
    @GestureState private var dragRotation: Float = 0
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    var body: some View {
        SceneKitKeyView(
            rotationAngle: $rotationAngle,
            dragRotation: dragRotation,
            fillLevel: progress > 0.001 ? Float(progress) : -1,
            isDark: colorScheme == .dark
        )
        .scaleEffect(pressScale)
        .gesture(
            DragGesture()
                .updating($dragRotation) { value, state, _ in
                    state = Float(value.translation.width) * 0.004
                }
                .onEnded { value in
                    rotationAngle += Float(value.translation.width) * 0.004
                    rotationAngle = max(-0.35, min(0.35, rotationAngle))
                }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.15)) {
                        pressScale = 0.96
                    }
                    withAnimation(.easeOut(duration: 0.2).delay(0.15)) {
                        pressScale = 1.0
                    }
                }
        )
        .accessibilityLabel(progress >= 1 ? "Blocked" : "Not blocked")
    }
}

struct SceneKitKeyView: UIViewRepresentable {
    @Binding var rotationAngle: Float
    var dragRotation: Float
    var fillLevel: Float
    var isDark: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.backgroundColor = .clear
        sceneView.isOpaque = false
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.antialiasingMode = .multisampling4X
        sceneView.clipsToBounds = false
        sceneView.isPlaying = true
        
        let scene = SCNScene()
        scene.background.contents = UIColor.clear
        
        let pivot = SCNNode()
        pivot.name = "keyPivot"
        
        if let modelURL = Bundle.main.url(forResource: "KeyModel", withExtension: "usdz") {
            do {
                let modelScene = try SCNScene(url: modelURL, options: nil)
                for child in modelScene.rootNode.childNodes {
                    pivot.addChildNode(child.clone())
                }
                Self.applyPBRMaterial(to: pivot)
                let materials = Self.collectMaterials(from: pivot)
                Self.installFillShader(on: materials)
                context.coordinator.materials = materials
                print("[KeyView3D] Loaded KeyModel.usdz, children: \(pivot.childNodes.count), materials: \(materials.count)")
            } catch {
                print("[KeyView3D] Failed to load model: \(error)")
            }
        } else {
            print("[KeyView3D] KeyModel.usdz not found in bundle")
        }
        
        scene.rootNode.addChildNode(pivot)
        context.coordinator.pivot = pivot
        
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = UIColor.white
        ambient.light?.intensity = 300
        scene.rootNode.addChildNode(ambient)
        
        let keyLight = SCNNode()
        keyLight.name = "keyLight"
        keyLight.light = SCNLight()
        keyLight.light?.type = .directional
        keyLight.light?.color = UIColor.white
        keyLight.light?.intensity = 900
        keyLight.light?.castsShadow = false
        // Upper left so the ring emboss still reads
        keyLight.eulerAngles = SCNVector3(-0.85, 0.65, 0)
        scene.rootNode.addChildNode(keyLight)
        
        let cameraNode = SCNNode()
        cameraNode.name = "keyCamera"
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 30
        cameraNode.camera?.automaticallyAdjustsZRange = true
        cameraNode.camera?.wantsHDR = false
        cameraNode.camera?.wantsExposureAdaptation = false
        scene.rootNode.addChildNode(cameraNode)
        context.coordinator.camera = cameraNode
        
        Self.frameCamera(cameraNode, around: pivot)
        
        sceneView.scene = scene
        sceneView.pointOfView = cameraNode
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        let yaw = dragRotation + rotationAngle
        context.coordinator.pivot?.eulerAngles.y = yaw
        if uiView.pointOfView == nil {
            uiView.pointOfView = context.coordinator.camera
        }
        let clay: UIColor = isDark
            ? UIColor(red: 0.45, green: 0.42, blue: 0.39, alpha: 1)
            : UIColor(red: 0.835, green: 0.80, blue: 0.745, alpha: 1)
        for material in context.coordinator.materials {
            material.diffuse.contents = clay
            material.setValue(NSNumber(value: Float(fillLevel)), forKey: "fillLevel")
        }
    }
    
    static func applyPBRMaterial(to node: SCNNode) {
        node.castsShadow = false
        if var geometry = node.geometry {
            geometry.wantsAdaptiveSubdivision = false
            geometry = smoothedGeometry(geometry)
            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.diffuse.contents = UIColor(red: 0.835, green: 0.80, blue: 0.745, alpha: 1)
            material.roughness.contents = NSNumber(value: 0.62)
            material.metalness.contents = NSNumber(value: 0.0)
            material.locksAmbientWithDiffuse = false
            material.ambient.contents = UIColor.black
            geometry.materials = [material]
            node.geometry = geometry
        }
        for child in node.childNodes {
            applyPBRMaterial(to: child)
        }
    }
    
    static func smoothedGeometry(_ geometry: SCNGeometry) -> SCNGeometry {
        let mesh = MDLMesh(scnGeometry: geometry)
        mesh.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 0.8)
        return SCNGeometry(mdlMesh: mesh)
    }
    
    static func frameCamera(_ cameraNode: SCNNode, around node: SCNNode) {
        let (center, radius) = worldBoundingSphere(of: node)
        cameraNode.camera?.fieldOfView = 30
        cameraNode.camera?.automaticallyAdjustsZRange = true
        // 55 degrees above the table so the disc face is a wide ellipse
        let elevation = 55 * Float.pi / 180
        let azimuth = 18 * Float.pi / 180
        let direction = simd_normalize(simd_float3(
            sin(azimuth) * cos(elevation),
            sin(elevation),
            cos(azimuth) * cos(elevation)
        ))
        // Fill most of the square view so the pebble is ~60% of the card
        let fovRadians = 30 * Float.pi / 180
        let discRadius: Float = 0.5
        let fillFraction: Float = 0.86
        let distance = discRadius / tan(fovRadians * 0.5 * fillFraction)
        let centerSIMD = simd_float3(center.x, center.y, center.z)
        cameraNode.simdPosition = centerSIMD + direction * distance
        cameraNode.look(
            at: SCNVector3(center.x, center.y, center.z),
            up: SCNVector3(0, 1, 0),
            localFront: SCNVector3(0, 0, -1)
        )
        print("[KeyView3D] Camera elev=55 deg dist=\(distance) r=\(radius)")
    }
    
    static func worldBoundingSphere(of node: SCNNode) -> (SCNVector3, Float) {
        let (minB, maxB) = node.boundingBox
        let corners = [
            SCNVector3(minB.x, minB.y, minB.z),
            SCNVector3(minB.x, minB.y, maxB.z),
            SCNVector3(minB.x, maxB.y, minB.z),
            SCNVector3(minB.x, maxB.y, maxB.z),
            SCNVector3(maxB.x, minB.y, minB.z),
            SCNVector3(maxB.x, minB.y, maxB.z),
            SCNVector3(maxB.x, maxB.y, minB.z),
            SCNVector3(maxB.x, maxB.y, maxB.z)
        ]
        let world = corners.map { node.convertPosition($0, to: nil) }
        var minP = world[0]
        var maxP = world[0]
        for p in world {
            minP.x = min(minP.x, p.x); minP.y = min(minP.y, p.y); minP.z = min(minP.z, p.z)
            maxP.x = max(maxP.x, p.x); maxP.y = max(maxP.y, p.y); maxP.z = max(maxP.z, p.z)
        }
        let center = SCNVector3(
            (minP.x + maxP.x) * 0.5,
            (minP.y + maxP.y) * 0.5,
            (minP.z + maxP.z) * 0.5
        )
        let dx = maxP.x - minP.x
        let dy = maxP.y - minP.y
        let dz = maxP.z - minP.z
        let radius = sqrt(dx * dx + dy * dy + dz * dz) * 0.5
        return (center, radius)
    }
    
    static func collectMaterials(from node: SCNNode) -> [SCNMaterial] {
        var materials: [SCNMaterial] = []
        if let geometry = node.geometry {
            materials.append(contentsOf: geometry.materials)
        }
        for child in node.childNodes {
            materials.append(contentsOf: collectMaterials(from: child))
        }
        return materials
    }
    
    static let fillSurfaceShader = """
    #pragma arguments
    float fillLevel;
    #pragma body
    float3 mp = (scn_node.inverseModelViewTransform * float4(_surface.position, 1.0)).xyz;
    // View-space Y is screen-up, so fillLevel 0.5 is a straight tide
    // across the top face and rim. mp keeps the object-space form.
    float t = clamp((_surface.position.y / 0.4) + 0.5, 0.0, 1.0);
    t = mix(clamp(mp.y + 0.5, 0.0, 1.0), t, 1.0);
    float m = smoothstep(fillLevel - 0.02, fillLevel + 0.02, t);
    _surface.diffuse.rgb = mix(_surface.diffuse.rgb * 0.55, _surface.diffuse.rgb, m);
    """
    
    static func installFillShader(on materials: [SCNMaterial]) {
        for material in materials {
            material.shaderModifiers = [
                .surface: fillSurfaceShader
            ]
            material.setValue(NSNumber(value: Float(-1.0)), forKey: "fillLevel")
        }
    }
    
    class Coordinator {
        var pivot: SCNNode?
        var camera: SCNNode?
        var materials: [SCNMaterial] = []
    }
}

#Preview {
    VStack {
        KeyView3D(progress: 0)
            .frame(width: 240, height: 240)
    }
    .padding()
    .background(Color.brickCanvas)
}
