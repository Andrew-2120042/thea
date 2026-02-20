import SwiftUI

// MARK: - Pure SwiftUI Confetti (no external dependencies)
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    private let particleCount = 60

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPieceView(particle: particle)
                }
            }
            .onAppear {
                launch(in: geo.size)
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private func launch(in size: CGSize) {
        particles = (0..<particleCount).map { i in
            ConfettiParticle(
                id: i,
                x: CGFloat.random(in: 0...size.width),
                color: confettiColors.randomElement() ?? .purple,
                shape: ConfettiShape.allCases.randomElement() ?? .rectangle,
                size: CGFloat.random(in: 6...14),
                delay: Double.random(in: 0...0.6),
                duration: Double.random(in: 2.0...3.5),
                screenHeight: size.height
            )
        }
    }

    private let confettiColors: [Color] = [
        Color(hex: "#8B5CF6"),
        Color(hex: "#EC4899"),
        Color(hex: "#F59E0B"),
        Color(hex: "#10B981"),
        Color(hex: "#3B82F6"),
        Color(hex: "#F97316"),
        .white,
    ]
}

// MARK: - Particle Model
struct ConfettiParticle: Identifiable {
    let id: Int
    let x: CGFloat
    let color: Color
    let shape: ConfettiShape
    let size: CGFloat
    let delay: Double
    let duration: Double
    let screenHeight: CGFloat
}

enum ConfettiShape: CaseIterable {
    case rectangle, circle, triangle
}

// MARK: - Particle View
struct ConfettiPieceView: View {
    let particle: ConfettiParticle
    @State private var yOffset: CGFloat = -20
    @State private var xDrift: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1.0

    var body: some View {
        confettiShape
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 0.6)
            .rotationEffect(.degrees(rotation))
            .offset(x: particle.x + xDrift, y: yOffset)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeIn(duration: particle.duration)
                    .delay(particle.delay)
                ) {
                    yOffset = particle.screenHeight + 100
                    xDrift = CGFloat.random(in: -60...60)
                    rotation = Double.random(in: 180...720)
                }
                withAnimation(
                    .easeIn(duration: 0.8)
                    .delay(particle.delay + particle.duration * 0.6)
                ) {
                    opacity = 0
                }
            }
    }

    private var confettiShape: AnyShape {
        switch particle.shape {
        case .rectangle:
            return AnyShape(RoundedRectangle(cornerRadius: 2))
        case .circle:
            return AnyShape(Circle())
        case .triangle:
            return AnyShape(Triangle())
        }
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

// MARK: - AnyShape wrapper
struct AnyShape: Shape, @unchecked Sendable {
    private let pathBuilder: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        self.pathBuilder = shape.path(in:)
    }

    func path(in rect: CGRect) -> Path {
        pathBuilder(rect)
    }
}
