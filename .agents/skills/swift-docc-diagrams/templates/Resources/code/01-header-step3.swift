import SwiftUI

struct ItemHeaderView: View {
    var body: some View {
        Image("hero-detail-view")
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    ItemHeaderView()
}
