import SwiftUI

struct MusicVisualizerView: View {
    let isPlaying: Bool
    let color: Color

    private let barCount = 3
    private let barWidth: CGFloat = 3
    private let gap: CGFloat = 2
    private let maxH: CGFloat = 16
    private let minH: CGFloat = 3

    @State private var levels: [CGFloat] = [0.35, 0.65, 0.45]
    @State private var animTask: Task<Void, Never>?

    var body: some View {
        HStack(alignment: .bottom, spacing: gap) {
            ForEach(0..<barCount, id: \.self) { i in
                Capsule()
                    .fill(color)
                    .frame(width: barWidth, height: max(minH, levels[i] * maxH))
                    .animation(.easeInOut(duration: 0.22), value: levels[i])
            }
        }
        .frame(width: CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * gap, height: maxH, alignment: .bottom)
        .onChange(of: isPlaying) { _, playing in
            playing ? startAnim() : stopAnim()
        }
        .onAppear   { if isPlaying { startAnim() } }
        .onDisappear { animTask?.cancel() }
    }

    private func startAnim() {
        animTask?.cancel()
        animTask = Task {
            while !Task.isCancelled {
                let next: [CGFloat] = (0..<barCount).map { _ in .random(in: 0.2...1.0) }
                await MainActor.run { levels = next }
                try? await Task.sleep(for: .milliseconds(Int.random(in: 180...380)))
            }
        }
    }

    private func stopAnim() {
        animTask?.cancel()
        withAnimation(.easeInOut(duration: 0.3)) {
            levels = [0.2, 0.15, 0.18]
        }
    }
}
