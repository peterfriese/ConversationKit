import SwiftUI

struct ItemHeaderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image("hero-detail-view")
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text("Item Title")
                .font(.headline)
        }
    }
}

#Preview {
    ItemHeaderView()
}
