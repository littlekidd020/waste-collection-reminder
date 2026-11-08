import SwiftUI

struct GuideView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        ZStack(alignment: .top) {
            LinenGround()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    TagLabel("What goes where")
                        .padding(.top, 72)
                    ForEach(Array(Sample.guideBins.enumerated()), id: \.element) { i, bin in
                        section(bin)
                            .padding(.top, i == 0 ? 24 : 56)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.85).delay(Double(i) * 0.04), value: appeared)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)

            HStack {
                Spacer()
                GlassCornerButton(symbol: "safari", label: "Open the council's guide")
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .onAppear { appeared = true }
    }

    private func section(_ bin: Bin) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(bin.name)
                    .font(.system(size: 32, weight: .regular, design: .serif))
                    .foregroundStyle(Palette.ink)
                Spacer()
                TagLabel(bin.frequency)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Sample.accepted(bin).prefix(4), id: \.self) { item in
                    tile(item, bin: bin)
                }
            }
            .padding(.top, 20)

            (Text("Not in this bin: ").foregroundStyle(Palette.ink)
             + Text(Sample.refused(bin).prefix(3).joined(separator: ", ").lowercasedFirstAfterFirst()))
                .font(.system(size: 15))
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)
        }
    }

    private func tile(_ item: String, bin: Bin) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: GuideSymbols.symbol(for: item))
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(Palette.ink.opacity(0.7))
                .frame(height: 38, alignment: .topLeading)
                .accessibilityHidden(true)
            Spacer(minLength: 8)
            Text(item)
                .font(.system(size: 15))
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .aspectRatio(1, contentMode: .fit)
        .background(Palette.surface, in: .rect(cornerRadius: 22))
        .overlay(alignment: .topTrailing) {
            LidSphere(bin: bin, size: 8)
                .padding(18)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item), \(bin.name)")
    }
}

enum GuideSymbols {
    static func symbol(for item: String) -> String {
        switch item {
        case "Nappies and sanitary products": return "figure.and.child.holdinghands"
        case "Soft plastics and wraps": return "bag"
        case "Polystyrene": return "shippingbox"
        case "Broken glass and ceramics": return "cup.and.saucer"
        case "Plastic bottles and containers 1, 2, 5": return "waterbottle"
        case "Tins and aluminium cans": return "cylinder"
        case "Paper and cardboard": return "newspaper"
        case "Pizza boxes, clean": return "takeoutbag.and.cup.and.straw"
        case "Fruit and vegetable scraps": return "carrot"
        case "Meat, fish and bones": return "fish"
        case "Bread, rice and pasta": return "fork.knife"
        case "Eggshells and coffee grounds": return "cup.and.heat.waves"
        default: return "circle.dotted"
        }
    }
}

extension String {
    /// "Recyclables, Batteries and electronics" -> "recyclables, batteries and electronics"
    func lowercasedFirstAfterFirst() -> String {
        split(separator: ",").map { part -> String in
            let s = part.trimmingCharacters(in: .whitespaces)
            return s.prefix(1).lowercased() + s.dropFirst()
        }.joined(separator: ", ")
    }
}
