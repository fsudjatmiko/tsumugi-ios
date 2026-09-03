import ARKit
import RealityKit
import SwiftUI

/// ARKit & RealityKit plane-projected surface canvas providing surface scanning, flat stencil projection, sequential multi-stroke validation, and animated 3D extrusion.
struct ARAirDrawingCanvas: UIViewRepresentable {
    let character: String
    let strokeCount: Int
    let isSurfaceLocked: Bool
    let isSuccess: Bool
    let clearTrigger: Int
    @Binding var hasDetectedSurface: Bool
    @Binding var currentStrokeIndex: Int
    @Binding var completedStrokeCount: Int
    var onPlaneTapped: (() -> Void)? = nil
    var onStrokeSuccess: ((Int) -> Void)? = nil
    var onCharacterCompleted: (() -> Void)? = nil

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        #if !targetEnvironment(simulator)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        arView.session.delegate = context.coordinator
        #endif

        context.coordinator.arView = arView

        // Focus Reticle Anchor
        let reticleAnchor = AnchorEntity()
        reticleAnchor.name = "ReticleAnchor"
        let reticleEntity = createReticleEntity()
        reticleAnchor.addChild(reticleEntity)
        arView.scene.addAnchor(reticleAnchor)
        context.coordinator.reticleAnchor = reticleAnchor
        context.coordinator.reticleEntity = reticleEntity

        // Tap Gesture for placing/locking surface template
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        // Pan Gesture for tracing strokes
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.isSurfaceLocked = isSurfaceLocked
        context.coordinator.isSuccess = isSuccess
        context.coordinator.onPlaneTapped = onPlaneTapped
        context.coordinator.onStrokeSuccess = onStrokeSuccess
        context.coordinator.onCharacterCompleted = onCharacterCompleted
        context.coordinator.strokeCount = strokeCount

        // Check if character changed
        if context.coordinator.currentCharacter != character {
            context.coordinator.currentCharacter = character
            context.coordinator.resetProgress()
            if context.coordinator.isSurfaceLocked {
                context.coordinator.setupSurfaceCharacter(character: character, isSuccess: isSuccess)
            }
        }

        // Check if surface lock state changed
        if isSurfaceLocked && context.coordinator.surfaceAnchor == nil {
            context.coordinator.lockCurrentSurface(character: character)
        }

        // Update completion state (animate to full 3D)
        if isSuccess != context.coordinator.lastSuccessState {
            context.coordinator.lastSuccessState = isSuccess
            if isSuccess {
                context.coordinator.elevateCharacterTo3D(character: character)
            }
        }

        // Handle clear trigger
        if clearTrigger != context.coordinator.lastClearTrigger {
            context.coordinator.lastClearTrigger = clearTrigger
            context.coordinator.resetProgress()
            context.coordinator.clearTrailEntities()
            if context.coordinator.isSurfaceLocked && !isSuccess {
                context.coordinator.setupSurfaceCharacter(character: character, isSuccess: false)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            hasDetectedSurface: $hasDetectedSurface,
            currentStrokeIndex: $currentStrokeIndex,
            completedStrokeCount: $completedStrokeCount
        )
    }

    // MARK: - Reticle Visual Entity

    private func createReticleEntity() -> ModelEntity {
        let mesh = MeshResource.generatePlane(width: 0.16, depth: 0.16, cornerRadius: 0.08)
        var material = SimpleMaterial()
        material.color = .init(tint: UIColor(Color.tsumugiChartreuse).withAlphaComponent(0.6))
        material.roughness = 0.5
        material.metallic = 0.5

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "reticleMesh"
        entity.isEnabled = false
        return entity
    }

    // MARK: - Coordinator

    @MainActor
    class Coordinator: NSObject, ARSessionDelegate {
        @Binding var hasDetectedSurface: Bool
        @Binding var currentStrokeIndex: Int
        @Binding var completedStrokeCount: Int

        var arView: ARView?
        var reticleAnchor: AnchorEntity?
        var reticleEntity: ModelEntity?
        var surfaceAnchor: AnchorEntity?
        var characterEntity: ModelEntity?
        var currentCharacter: String = ""
        var strokeCount: Int = 1
        var isSurfaceLocked: Bool = false
        var isSuccess: Bool = false
        var lastSuccessState: Bool = false
        var lastClearTrigger: Int = 0
        var lastHitTransform: simd_float4x4?

        var onPlaneTapped: (() -> Void)?
        var onStrokeSuccess: ((Int) -> Void)?
        var onCharacterCompleted: (() -> Void)?

        // Stroke Tracking State
        private let validator = ARStrokeValidator()
        private var activeStrokePoints: [CGPoint] = []
        private var activeStrokeEntities: [ModelEntity] = []
        private var completedStrokesSet: Set<Int> = []
        private let planePhysicalWidth: Float = 0.14 // 14cm character bounding box on surface

        init(
            hasDetectedSurface: Binding<Bool>,
            currentStrokeIndex: Binding<Int>,
            completedStrokeCount: Binding<Int>
        ) {
            self._hasDetectedSurface = hasDetectedSurface
            self._currentStrokeIndex = currentStrokeIndex
            self._completedStrokeCount = completedStrokeCount
        }

        func resetProgress() {
            completedStrokesSet.removeAll()
            activeStrokePoints.removeAll()
            activeStrokeEntities.removeAll()
            currentStrokeIndex = 0
            completedStrokeCount = 0
        }

        // MARK: - ARSessionDelegate Raycasting

        nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
            Task { @MainActor in
                guard let arView = self.arView, !self.isSurfaceLocked else {
                    self.reticleEntity?.isEnabled = false
                    return
                }

                let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
                guard center.x > 0, center.y > 0 else { return }

                // Periodic raycasting against detected horizontal planes
                let results = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .horizontal)
                if let firstHit = results.first {
                    self.lastHitTransform = firstHit.worldTransform
                    self.reticleAnchor?.setTransformMatrix(firstHit.worldTransform, relativeTo: nil)
                    self.reticleEntity?.isEnabled = true
                    if !self.hasDetectedSurface {
                        self.hasDetectedSurface = true
                    }
                } else {
                    self.reticleEntity?.isEnabled = false
                    if self.hasDetectedSurface {
                        self.hasDetectedSurface = false
                    }
                }
            }
        }

        // MARK: - Surface Lock & Template Projection

        func lockCurrentSurface(character: String) {
            guard let arView = arView, let transform = lastHitTransform else { return }
            isSurfaceLocked = true
            reticleEntity?.isEnabled = false

            // Create Anchor oriented flat onto the detected surface
            let anchor = AnchorEntity(world: transform)
            anchor.name = "SurfaceAnchor"
            arView.scene.addAnchor(anchor)
            self.surfaceAnchor = anchor

            setupSurfaceCharacter(character: character, isSuccess: false)
        }

        func setupSurfaceCharacter(character: String, isSuccess: Bool) {
            guard let anchor = surfaceAnchor else { return }
            clearAllAnchorChildren(anchor: anchor)

            // Flat low-opacity guide stencil on surface (Stage 2)
            let textMesh = MeshResource.generateText(
                character,
                extrusionDepth: isSuccess ? 0.035 : 0.002,
                font: .systemFont(ofSize: CGFloat(planePhysicalWidth), weight: .bold),
                containerFrame: .zero,
                alignment: .center
            )

            let tintColor = isSuccess
                ? UIColor(Color.tsumugiChartreuse)
                : UIColor(Color.tsumugiDustyDenim).withAlphaComponent(0.35)

            let material = SimpleMaterial(color: tintColor, roughness: 0.3, isMetallic: isSuccess)
            let entity = ModelEntity(mesh: textMesh, materials: [material])
            entity.name = "surfaceCharacterModel"

            // Center glyph and orient flat on horizontal surface (-90 degrees on X-axis)
            let bounds = entity.visualBounds(relativeTo: nil)
            entity.position = [
                -(bounds.extents.x / 2.0 + bounds.min.x),
                isSuccess ? 0.02 : 0.001,
                -(bounds.extents.y / 2.0 + bounds.min.y)
            ]
            entity.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])

            anchor.addChild(entity)
            self.characterEntity = entity

            updateGuideIndicators(character: character)
        }

        private func updateGuideIndicators(character: String) {
            guard let anchor = surfaceAnchor, !isSuccess else { return }

            // Remove previous guide dots
            let oldDots = anchor.children.filter { $0.name == "guideDot" }
            for d in oldDots { d.removeFromParent() }

            let guide = StrokeGuide.defaultGuide(for: character, strokeCount: strokeCount)
            let targetIdx = currentStrokeIndex

            guard targetIdx < guide.strokes.count else { return }
            let activeSegment = guide.strokes[targetIdx]

            // Render glowing start indicator dot for current active stroke
            let dotOffset = SIMD3<Float>(
                Float((activeSegment.startPoint.x - 0.5) * CGFloat(planePhysicalWidth)),
                0.004,
                Float((activeSegment.startPoint.y - 0.5) * CGFloat(planePhysicalWidth))
            )
            let startDot = SpatialKanjiGenerator.shared.createTrailPointEntity(
                position: dotOffset,
                radius: 0.007,
                color: UIColor(Color.tsumugiChartreuse)
            )
            startDot.name = "guideDot"
            anchor.addChild(startDot)

            // Render subtle end dot
            let endOffset = SIMD3<Float>(
                Float((activeSegment.endPoint.x - 0.5) * CGFloat(planePhysicalWidth)),
                0.003,
                Float((activeSegment.endPoint.y - 0.5) * CGFloat(planePhysicalWidth))
            )
            let endDot = SpatialKanjiGenerator.shared.createTrailPointEntity(
                position: endOffset,
                radius: 0.004,
                color: UIColor(Color.tsumugiDustyDenim).withAlphaComponent(0.6)
            )
            endDot.name = "guideDot"
            anchor.addChild(endDot)
        }

        // MARK: - Elevate to 3D on Completion (Stage 3)

        func elevateCharacterTo3D(character: String) {
            guard let anchor = surfaceAnchor else { return }
            clearAllAnchorChildren(anchor: anchor)

            let textMesh = MeshResource.generateText(
                character,
                extrusionDepth: 0.035,
                font: .systemFont(ofSize: CGFloat(planePhysicalWidth), weight: .bold),
                containerFrame: .zero,
                alignment: .center
            )
            let material = SimpleMaterial(color: UIColor(Color.tsumugiChartreuse), roughness: 0.2, isMetallic: true)
            let entity = ModelEntity(mesh: textMesh, materials: [material])
            entity.name = "surfaceCharacterModel"

            let bounds = entity.visualBounds(relativeTo: nil)
            entity.position = [
                -(bounds.extents.x / 2.0 + bounds.min.x),
                0.025, // Elevate 2.5cm above surface
                -(bounds.extents.y / 2.0 + bounds.min.y)
            ]
            entity.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])

            anchor.addChild(entity)
            self.characterEntity = entity
        }

        func clearTrailEntities() {
            guard let anchor = surfaceAnchor else { return }
            let trails = anchor.children.filter { $0.name == "inkTrail" || $0.name == "tempInkTrail" }
            for t in trails {
                t.removeFromParent()
            }
        }

        private func clearAllAnchorChildren(anchor: AnchorEntity) {
            for child in anchor.children {
                child.removeFromParent()
            }
        }

        // MARK: - Gestures & Multi-Stroke Validation

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            if !isSurfaceLocked && hasDetectedSurface {
                onPlaneTapped?()
            }
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let arView = arView, let anchor = surfaceAnchor, isSurfaceLocked, !isSuccess else { return }
            let location = gesture.location(in: arView)

            switch gesture.state {
            case .began:
                activeStrokePoints.removeAll()
                activeStrokeEntities.removeAll()

            case .changed:
                let hits = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
                if let hit = hits.first {
                    let worldPos = hit.worldTransform.columns.3
                    let localPos = anchor.convert(position: SIMD3<Float>(worldPos.x, worldPos.y, worldPos.z), from: nil)

                    // Normalize to 0.0 ... 1.0 bounding box
                    let normX = CGFloat((localPos.x / planePhysicalWidth) + 0.5)
                    let normY = CGFloat((localPos.z / planePhysicalWidth) + 0.5)
                    activeStrokePoints.append(CGPoint(x: normX, y: normY))

                    let inkTrail = SpatialKanjiGenerator.shared.createTrailPointEntity(
                        position: [localPos.x, 0.003, localPos.z],
                        radius: 0.005,
                        color: UIColor(Color.tsumugiChartreuse)
                    )
                    inkTrail.name = "tempInkTrail"
                    anchor.addChild(inkTrail)
                    activeStrokeEntities.append(inkTrail)
                }

            case .ended:
                let guide = StrokeGuide.defaultGuide(for: currentCharacter, strokeCount: strokeCount)
                let targetIdx = currentStrokeIndex

                if targetIdx < guide.strokes.count {
                    let expectedSeg = guide.strokes[targetIdx]
                    let isValid = validator.validate(
                        normalizedPoints: activeStrokePoints,
                        expectedSegment: expectedSeg,
                        tolerance: 0.32
                    )

                    if isValid {
                        // Lock ink trail
                        for entity in activeStrokeEntities {
                            entity.name = "inkTrail"
                        }
                        completedStrokesSet.insert(targetIdx)
                        completedStrokeCount = completedStrokesSet.count
                        onStrokeSuccess?(targetIdx)

                        if completedStrokesSet.count >= guide.strokes.count {
                            // Full character completed!
                            onCharacterCompleted?()
                        } else {
                            // Advance to next stroke
                            currentStrokeIndex += 1
                            updateGuideIndicators(character: currentCharacter)
                        }
                    } else {
                        // Gesture invalid or lifted mid-stroke before reaching target: clear temporary ink
                        for entity in activeStrokeEntities {
                            entity.removeFromParent()
                        }
                    }
                }
                activeStrokePoints.removeAll()
                activeStrokeEntities.removeAll()

            case .cancelled:
                for entity in activeStrokeEntities {
                    entity.removeFromParent()
                }
                activeStrokePoints.removeAll()
                activeStrokeEntities.removeAll()

            default:
                break
            }
        }
    }
}
