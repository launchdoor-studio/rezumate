import SwiftUI

struct VariantDetailView: View {
    let variant: VariantDetail

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(variant.variantName)
                    .font(.title2.weight(.bold))
                Text("Score \(variant.atsScore ?? 0)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(variant.tailoredContent.rawText ?? "No resume text saved for this variant.")
                    .font(.body.monospaced())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .navigationTitle("Variant")
    }
}
