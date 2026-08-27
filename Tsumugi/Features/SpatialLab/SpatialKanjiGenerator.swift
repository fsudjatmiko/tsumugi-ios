import Foundation
import RealityKit
import SwiftUI

/// Service generating 3D RealityKit entities and materials for Japanese characters and radicals.
@MainActor
public final class SpatialKanjiGenerator {
    public static let shared = SpatialKanjiGenerator()

    public init() {}

    /// Generates a floating 3D text entity for a given Japanese character.
    ///
    /// - Parameters:
    ///   - character: The Japanese glyph to render.
    ///   - extrusionDepth: Depth of 3D text extrusion in meters.
    ///   - font: Font configuration for the text mesh.
    ///   - isHighlighted: Whether to render with active highlight material.
    /// - Returns: A configured `ModelEntity` ready for placement in a RealityKit scene.
    public func createCharacterEntity(
        character: String,
        extrusionDepth: Float = 0.03,
        font: MeshResource.Font = .systemFont(ofSize: 0.18, weight: .bold),
        isHighlighted: Bool = false
    ) -> ModelEntity {
        let mesh = MeshResource.generateText(
            character,
            extrusionDepth: extrusionDepth,
            font: font,
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byClipping
        )

        let material = makeMaterial(isHighlighted: isHighlighted)
        let entity = ModelEntity(mesh: mesh, materials: [material])

        // Center origin bounds
        let bounds = entity.visualBounds(relativeTo: nil)
        entity.position = [-bounds.center.x, -bounds.center.y, -bounds.center.z]

        let container = ModelEntity()
        container.addChild(entity)
        return container
    }

    /// Generates a small 3D sphere marker for air-tracing trail points.
    public func createTrailPointEntity(
        position: SIMD3<Float>,
        radius: Float = 0.008,
        color: UIColor? = nil
    ) -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: radius)
        var material = SimpleMaterial()
        let resolvedColor = color ?? UIColor(Color.tsumugiChartreuse)
        material.color = .init(tint: resolvedColor)
        material.roughness = 0.2
        material.metallic = 0.8

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = position
        return entity
    }

    /// Creates brand-tinted SimpleMaterial for character models.
    public func makeMaterial(isHighlighted: Bool) -> SimpleMaterial {
        var material = SimpleMaterial()
        let tintColor: UIColor = isHighlighted
            ? UIColor(Color.tsumugiChartreuse)
            : UIColor(Color.tsumugiDustyDenim)

        material.color = .init(tint: tintColor)
        material.roughness = 0.35
        material.metallic = isHighlighted ? 0.6 : 0.2
        return material
    }
}
