import SwiftUI

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var angle: Double
    var speed: Double
    var color: Color
    var scale: Double
    var rotation: Double
}

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var animating = false

    private let colors: [Color] = [
        Color("Teal"), Color("TealLight"), .yellow, .orange, .pink, .purple
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            Canvas { context, size in
                for particle in particles {
                    var ctx = context
                    ctx.translateBy(x: particle.x, y: particle.y)
                    ctx.rotate(by: .degrees(particle.rotation))
                    let rect = CGRect(
                        x: -4 * particle.scale,
                        y: -2.5 * particle.scale,
                        width: 8 * particle.scale,
                        height: 5 * particle.scale
                    )
                    let path = Path(ellipseIn: rect)
                    ctx.fill(path, with: .color(particle.color))
                }
            }
            .onChange(of: timeline.date) { _, _ in
                updateParticles()
            }
        }
        .onAppear { spawnParticles() }
        .allowsHitTesting(false)
    }

    private func spawnParticles() {
        particles = (0..<30).map { _ in
            ConfettiParticle(
                x: Double.random(in: 20...200),
                y: 0,
                angle: Double.random(in: -30...30),
                speed: Double.random(in: 3...8),
                color: colors.randomElement() ?? Color("Teal"),
                scale: Double.random(in: 0.5...1.5),
                rotation: Double.random(in: 0...360)
            )
        }
    }

    private func updateParticles() {
        particles = particles.compactMap { p in
            var updated = p
            updated.x += sin(p.angle * .pi / 180) * 2
            updated.y += p.speed
            updated.rotation += 5
            return updated.y < 300 ? updated : nil
        }
    }
}
