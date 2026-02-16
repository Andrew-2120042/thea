import SwiftUI

// Renders affirmation word-by-word, lighting up each word as it's recognised.
// Uses Text concatenation so the result wraps naturally (no custom flow layout needed).
struct HighlightedAffirmationText: View {
    let affirmation: String
    let recognizedWords: [String]

    private var words: [String] {
        affirmation.components(separatedBy: " ").filter { !$0.isEmpty }
    }

    var body: some View {
        highlightedText
            .multilineTextAlignment(.center)
            .lineSpacing(8)
    }

    // Build a single Text by concatenating per-word styled segments
    private var highlightedText: Text {
        words.enumerated().reduce(Text("")) { result, pair in
            let (idx, word) = pair
            let clean = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
            let hit = recognizedWords.contains { matchWords(clean, $0) }
            let spacer = idx < words.count - 1 ? " " : ""
            let segment = Text(word + spacer)
                .foregroundColor(hit ? .white : .white.opacity(0.28))
                .font(hit
                    ? .system(size: 30, weight: .semibold, design: .serif)
                    : .system(size: 30, weight: .regular, design: .serif))
            return result + segment
        }
    }

    // MARK: - Completion

    /// 0.0 – 1.0 fraction of words matched
    var completionPercentage: Double {
        let total = words.count
        guard total > 0 else { return 0 }
        let clean = words.map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) }
        let matched = clean.filter { w in
            recognizedWords.contains { matchWords(w, $0) }
        }.count
        return Double(matched) / Double(total)
    }

    // MARK: - Word matching

    private func matchWords(_ a: String, _ b: String) -> Bool {
        if a == b { return true }

        // Contraction expansion
        let contractions: [String: [String]] = [
            "i'm": ["i", "am"], "you're": ["you", "are"], "it's": ["it", "is"],
            "i've": ["i", "have"], "we're": ["we", "are"], "they're": ["they", "are"],
            "that's": ["that", "is"], "what's": ["what", "is"],
            "there's": ["there", "is"], "here's": ["here", "is"],
            "i'll": ["i", "will"], "can't": ["cannot"], "don't": ["do", "not"],
            "won't": ["will", "not"]
        ]
        if let exp = contractions[b], exp.contains(a) { return true }
        if let exp = contractions[a], exp.contains(b) { return true }

        // Fuzzy: allow 1 edit for short words, 2 for longer
        let threshold = max(a.count, b.count) <= 4 ? 1 : 2
        return levenshtein(a, b) <= threshold
    }

    private func levenshtein(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1), b = Array(s2)
        var dp = Array(0...b.count)
        for i in 1...max(a.count, 1) {
            guard i <= a.count else { break }
            var prev = dp[0]
            dp[0] = i
            for j in 1...b.count {
                let temp = dp[j]
                dp[j] = a[i-1] == b[j-1] ? prev : 1 + min(prev, dp[j], dp[j-1])
                prev = temp
            }
        }
        return dp[b.count]
    }
}
