import Foundation
import SwiftUI

struct DefaultCategories {
    static let defaults: [Category] = [
        
        // MARK: - 🟢 GELİR KATEGORİLERİ (INCOME)
        
        Category(
            name: "Maaş & Kariyer",
            icon: "banknote.fill",
            colorHex: "#34C759", // Sistem Yeşili
            type: .income,
            subCategories: [
                SubCategory(name: "Ana Maaş", icon: "dollarsign.circle.fill", colorHex: "#34C759"),
                SubCategory(name: "Ek Mesai", icon: "clock.fill", colorHex: "#30D158"),
                SubCategory(name: "Prim & Bonus", icon: "gift.fill", colorHex: "#28CD41"),
                SubCategory(name: "Freelance / Proje", icon: "laptopcomputer", colorHex: "#32D74B"),
                SubCategory(name: "Kıdem / İhbar Tazminatı", icon: "doc.text.fill", colorHex: "#1DB954"),
                SubCategory(name: "Huzur Hakkı", icon: "person.2.fill", colorHex: "#34C759")
            ]
        ),
        Category(
            name: "Yatırım & Finans",
            icon: "chart.line.uptrend.xyaxis",
            colorHex: "#00C7BE", // Teal
            type: .income,
            subCategories: [
                SubCategory(name: "Hisse Senedi / Temettü", icon: "chart.bar.fill", colorHex: "#40C8E0"),
                SubCategory(name: "Kripto Varlık Kârı", icon: "bitcoinsign.circle.fill", colorHex: "#FFD60A"),
                SubCategory(name: "Mevduat Faizi", icon: "percent", colorHex: "#63E6E2"),
                SubCategory(name: "Fon Getirisi", icon: "pi.circle.fill", colorHex: "#30B0C7"),
                SubCategory(name: "Döviz Kur Farkı", icon: "eurosign.circle.fill", colorHex: "#59ADC4"),
                SubCategory(name: "Altın / Değerli Maden", icon: "target", colorHex: "#FFCC00")
            ]
        ),
        Category(
            name: "Gayrimenkul & Pasif",
            icon: "house.fill",
            colorHex: "#5856D6", // Indigo
            type: .income,
            subCategories: [
                SubCategory(name: "Konut Kira Geliri", icon: "house.circle.fill", colorHex: "#5E5CE6"),
                SubCategory(name: "İşyeri Kira Geliri", icon: "building.2.fill", colorHex: "#AC8E68"),
                SubCategory(name: "Airbnb / Kısa Dönem", icon: "bed.double.fill", colorHex: "#FF385C"),
                SubCategory(name: "Telif & Lisans Hakları", icon: "c.circle.fill", colorHex: "#AF52DE")
            ]
        ),
        Category(
            name: "Diğer Gelirler",
            icon: "plus.circle.fill",
            colorHex: "#8E8E93", // Gri
            type: .income,
            subCategories: [
                SubCategory(name: "Nakit Hediye", icon: "gift.fill", colorHex: "#BF5AF2"),
                SubCategory(name: "Vergi İadesi", icon: "scroll.fill", colorHex: "#AC8E68"),
                SubCategory(name: "İkinci El Satış", icon: "tag.fill", colorHex: "#FF9F0A"),
                SubCategory(name: "Borç Tahsilatı", icon: "hand.thumbsup.fill", colorHex: "#5AC8FA"),
                SubCategory(name: "Piyango / Şans Oyunu", icon: "sparkles", colorHex: "#FF2D55"),
                SubCategory(name: "Burs / Yardım", icon: "studentdesk", colorHex: "#32ADE6")
            ]
        ),
        
        // MARK: - 🔴 GİDER KATEGORİLERİ (EXPENSE)
        
        // --- 1. Dijital Abonelikler (Genişletilmiş) ---
        Category(
            name: "Dijital Abonelikler",
            icon: "apps.iphone",
            colorHex: "#AF52DE", // Mor
            type: .expense,
            subCategories: [
                // AI & Teknoloji
                SubCategory(name: "ChatGPT Plus", icon: "brain.headset", colorHex: "#10A37F"),
                SubCategory(name: "Claude Pro", icon: "sparkles", colorHex: "#D97757"),
                SubCategory(name: "Midjourney", icon: "shimmer", colorHex: "#FFFFFF"),
                SubCategory(name: "Perplexity AI", icon: "magnifyingglass.circle", colorHex: "#20B2AA"),
                SubCategory(name: "Notion Plus", icon: "doc.text.inverse", colorHex: "#000000"),
                
                // Video & Film
                SubCategory(name: "Netflix", icon: "play.tv.fill", colorHex: "#E50914"),
                SubCategory(name: "Disney+", icon: "play.circle.fill", colorHex: "#113CCF"),
                SubCategory(name: "Amazon Prime Video", icon: "arrow.right.circle.fill", colorHex: "#00A8E1"),
                SubCategory(name: "YouTube Premium", icon: "play.rectangle.fill", colorHex: "#FF0000"),
                SubCategory(name: "Apple TV+", icon: "tv.fill", colorHex: "#000000"),
                SubCategory(name: "MUBI", icon: "film.fill", colorHex: "#000000"),
                SubCategory(name: "BluTV", icon: "play.fill", colorHex: "#00BFFF"),
                SubCategory(name: "GAİN", icon: "g.circle.fill", colorHex: "#CCFF00"),
                SubCategory(name: "Exxen", icon: "e.circle.fill", colorHex: "#FBC02D"),
                
                // Müzik & Ses
                SubCategory(name: "Spotify", icon: "music.note.list", colorHex: "#1DB954"),
                SubCategory(name: "Apple Music", icon: "music.note", colorHex: "#FB233B"),
                SubCategory(name: "YouTube Music", icon: "play.circle", colorHex: "#FF0000"),
                SubCategory(name: "Tidal", icon: "waveform", colorHex: "#000000"),
                SubCategory(name: "Deezer", icon: "equalizer.fill", colorHex: "#A238FF"),
                SubCategory(name: "Fizy", icon: "music.mic", colorHex: "#6EDDFF"),

                // Depolama & Bulut
                SubCategory(name: "iCloud+", icon: "cloud.fill", colorHex: "#007AFF"),
                SubCategory(name: "Google One (Drive)", icon: "externaldrive.fill", colorHex: "#4285F4"),
                SubCategory(name: "Dropbox", icon: "archivebox.fill", colorHex: "#0061FF"),
                SubCategory(name: "Microsoft 365", icon: "grid.circle.fill", colorHex: "#D83B01"),
                
                // Oyun & Eğlence
                SubCategory(name: "PlayStation Plus", icon: "gamecontroller.fill", colorHex: "#003791"),
                SubCategory(name: "Xbox Game Pass", icon: "xbox.logo", colorHex: "#107C10"),
                SubCategory(name: "Nintendo Switch Online", icon: "n.circle.fill", colorHex: "#E60012"),
                SubCategory(name: "Discord Nitro", icon: "bubble.left.and.bubble.right.fill", colorHex: "#5865F2"),
                SubCategory(name: "Steam", icon: "desktopcomputer", colorHex: "#171A21"),
                SubCategory(name: "Twitch", icon: "video.fill", colorHex: "#9146FF"),
                
                // İş & Sosyal
                SubCategory(name: "LinkedIn Premium", icon: "person.badge.shield.checkmark.fill", colorHex: "#0077B5"),
                SubCategory(name: "Adobe Creative Cloud", icon: "paintbrush.fill", colorHex: "#FF3C00"),
                SubCategory(name: "Canva Pro", icon: "pencil.tip.crop.circle.fill", colorHex: "#00C4CC"),
                SubCategory(name: "X Premium (Twitter)", icon: "xmark.circle.fill", colorHex: "#000000"),
                SubCategory(name: "Medium Membership", icon: "doc.plaintext.fill", colorHex: "#000000"),
                
                // Eğitim & Dil
                SubCategory(name: "Udemy", icon: "book.closed.fill", colorHex: "#A435F0"),
                SubCategory(name: "Coursera", icon: "graduationcap.fill", colorHex: "#0056D2"),
                SubCategory(name: "Duolingo Super", icon: "bird.fill", colorHex: "#58CC02"),
                SubCategory(name: "Busuu / Babbel", icon: "character.book.closed.fill", colorHex: "#29ABFF"),
                
                // Sağlık & Spor
                SubCategory(name: "Strava", icon: "figure.run.circle.fill", colorHex: "#FC4C02"),
                SubCategory(name: "Calm / Headspace", icon: "heart.circle.fill", colorHex: "#4A90E2"),
                SubCategory(name: "MyFitnessPal", icon: "figure.strengthtraining.traditional", colorHex: "#0066EE"),
                SubCategory(name: "Flo Premium", icon: "calendar.circle.fill", colorHex: "#FF708E"),
                
                // Diğer Servisler
                SubCategory(name: "NordVPN / Surfshark", icon: "shield.fill", colorHex: "#4682B4"),
                SubCategory(name: "Amazon Prime (Alışveriş)", icon: "cart.fill", colorHex: "#FF9900"),
                SubCategory(name: "Getir / Yemeksepeti Plus", icon: "motorcycle.fill", colorHex: "#5D3EBD"),
                SubCategory(name: "Bitwarden / 1Password", icon: "key.fill", colorHex: "#175DDC")
            ]
        ),
        
        // --- 2. Faturalar & Ödemeler ---
        Category(
            name: "Faturalar & Ödemeler",
            icon: "doc.text.fill",
            colorHex: "#FF3B30", // Kırmızı
            type: .expense,
            subCategories: [
                SubCategory(name: "Elektrik", icon: "bolt.fill", colorHex: "#FFCC00"),
                SubCategory(name: "Su", icon: "drop.fill", colorHex: "#32ADE6"),
                SubCategory(name: "Doğalgaz / Isınma", icon: "flame.fill", colorHex: "#FF9500"),
                SubCategory(name: "İnternet / Fiber", icon: "wifi", colorHex: "#007AFF"),
                SubCategory(name: "Telefon / GSM", icon: "iphone", colorHex: "#5856D6"),
                SubCategory(name: "Apartman Aidatı", icon: "building.2.fill", colorHex: "#8E8E93"),
                SubCategory(name: "Emlak / Çöp Vergisi", icon: "governingbody", colorHex: "#AC8E68"),
                SubCategory(name: "Gelir / MTV Vergisi", icon: "building.columns.fill", colorHex: "#636366")
            ]
        ),
        
        // --- 3. Gıda & Mutfak ---
        Category(
            name: "Gıda & Mutfak",
            icon: "cart.fill",
            colorHex: "#FF9500", // Turuncu
            type: .expense,
            subCategories: [
                SubCategory(name: "Süpermarket / Market", icon: "basket.fill", colorHex: "#FFAC1C"),
                SubCategory(name: "Kasap / Manav", icon: "carrot.fill", colorHex: "#34C759"),
                SubCategory(name: "Restoran", icon: "fork.knife", colorHex: "#FF3B30"),
                SubCategory(name: "Kafe / Kahve", icon: "cup.and.saucer.fill", colorHex: "#A2845E"),
                SubCategory(name: "Fast Food", icon: "takeoutbag.and.cup.and.straw.fill", colorHex: "#FFCC00"),
                SubCategory(name: "Eve Sipariş (Yemek)", icon: "motorcycle.fill", colorHex: "#FF2D55"),
                SubCategory(name: "Alkol & Tütün", icon: "wineglass.fill", colorHex: "#5856D6")
            ]
        ),
        
        // --- 4. Ulaşım & Araç ---
        Category(
            name: "Ulaşım & Araç",
            icon: "car.fill",
            colorHex: "#007AFF", // Mavi
            type: .expense,
            subCategories: [
                SubCategory(name: "Akaryakıt", icon: "fuelpump.fill", colorHex: "#FF3B30"),
                SubCategory(name: "Elektrikli Şarj", icon: "bolt.car.fill", colorHex: "#34C759"),
                SubCategory(name: "Toplu Taşıma / Akbil", icon: "bus.fill", colorHex: "#5AC8FA"),
                SubCategory(name: "Taksi / Uber / Martı", icon: "car.circle.fill", colorHex: "#FFD60A"),
                SubCategory(name: "Araç Bakım / Servis", icon: "wrench.and.screwdriver.fill", colorHex: "#636366"),
                SubCategory(name: "Otopark / HGS", icon: "p.circle.fill", colorHex: "#8E8E93"),
                SubCategory(name: "Araç Sigortası / Kasko", icon: "shield.checkerboard", colorHex: "#AF52DE")
            ]
        ),
        
        // --- 5. Konut & Yaşam ---
        Category(
            name: "Konut & Yaşam",
            icon: "house.fill",
            colorHex: "#AF52DE", // Mor
            type: .expense,
            subCategories: [
                SubCategory(name: "Kira Ödemesi", icon: "house", colorHex: "#BF5AF2"),
                SubCategory(name: "Konut Kredisi", icon: "key.fill", colorHex: "#30B0C7"),
                SubCategory(name: "Ev Bakım / Tamirat", icon: "hammer.fill", colorHex: "#AC8E68"),
                SubCategory(name: "Mobilya / Dekorasyon", icon: "sofa.fill", colorHex: "#D9B591"),
                SubCategory(name: "Beyaz Eşya", icon: "washer.fill", colorHex: "#5AC8FA"),
                SubCategory(name: "Temizlik Malzemesi", icon: "bubbles.and.sparkles.fill", colorHex: "#34C759")
            ]
        ),
        
        // --- 6. Sağlık & Bakım ---
        Category(
            name: "Sağlık & Bakım",
            icon: "heart.fill",
            colorHex: "#FF2D55", // Pembe
            type: .expense,
            subCategories: [
                SubCategory(name: "Eczane / İlaç", icon: "pills.fill", colorHex: "#FF6961"),
                SubCategory(name: "Hastane / Muayene", icon: "cross.case.fill", colorHex: "#FF453A"),
                SubCategory(name: "Diş Sağlığı", icon: "mouth.fill", colorHex: "#F2F2F7"),
                SubCategory(name: "Gözlük / Lens", icon: "eyeglasses", colorHex: "#5856D6"),
                SubCategory(name: "Psikolog / Terapi", icon: "face.smiling.fill", colorHex: "#32ADE6"),
                SubCategory(name: "Kuaför / Berber", icon: "scissors", colorHex: "#AC8E68"),
                SubCategory(name: "Kozmetik / Parfüm", icon: "sparkles", colorHex: "#FF9F0A"),
                SubCategory(name: "Spor Salonu", icon: "figure.strengthtraining.traditional", colorHex: "#34C759")
            ]
        ),
        
        // --- 7. Alışveriş & Giyim ---
        Category(
            name: "Alışveriş & Giyim",
            icon: "bag.fill",
            colorHex: "#32ADE6", // Açık Mavi
            type: .expense,
            subCategories: [
                SubCategory(name: "Giyim / Ayakkabı", icon: "tshirt.fill", colorHex: "#5AC8FA"),
                SubCategory(name: "Elektronik / Teknoloji", icon: "laptopcomputer", colorHex: "#5856D6"),
                SubCategory(name: "Aksesuar / Takı", icon: "watch.analog", colorHex: "#FFD60A"),
                SubCategory(name: "Hobi / Oyun", icon: "puzzlepiece.fill", colorHex: "#FF9500"),
                SubCategory(name: "Kitap / Kırtasiye", icon: "book.closed.fill", colorHex: "#AF52DE")
            ]
        ),
        
        // --- 8. Eğlence & Sosyal ---
        Category(
            name: "Eğlence & Sosyal",
            icon: "film.fill",
            colorHex: "#FF375F", // Koyu Pembe
            type: .expense,
            subCategories: [
                SubCategory(name: "Sinema / Konser", icon: "popcorn.fill", colorHex: "#FF375F"),
                SubCategory(name: "Gece Hayatı / Bar", icon: "wineglass.fill", colorHex: "#5856D6"),
                SubCategory(name: "Tatil / Otel", icon: "bed.double.fill", colorHex: "#30B0C7"),
                SubCategory(name: "Uçak / Bilet", icon: "airplane", colorHex: "#007AFF"),
                SubCategory(name: "Müze / Etkinlik", icon: "building.columns.fill", colorHex: "#AC8E68")
            ]
        ),
        
        // --- 9. Evcil Hayvan ---
        Category(
            name: "Evcil Hayvan",
            icon: "pawprint.fill",
            colorHex: "#A2845E", // Kahverengi
            type: .expense,
            subCategories: [
                SubCategory(name: "Mama / Gıda", icon: "dog.fill", colorHex: "#A2845E"),
                SubCategory(name: "Veteriner", icon: "cross.fill", colorHex: "#FF3B30"),
                SubCategory(name: "Oyuncak / Aksesuar", icon: "tennisball.fill", colorHex: "#FFCC00"),
                SubCategory(name: "Bakım / Kuaför", icon: "comb.fill", colorHex: "#5AC8FA")
            ]
        ),
        
        // --- 10. Borç & Finans ---
        Category(
            name: "Borç & Finans",
            icon: "creditcard.fill",
            colorHex: "#636366", // Koyu Gri
            type: .expense,
            subCategories: [
                SubCategory(name: "Kredi Kartı Ödemesi", icon: "creditcard.and.123", colorHex: "#8E8E93"),
                SubCategory(name: "Kredi Taksiti", icon: "dollarsign.arrow.circlepath", colorHex: "#FF3B30"),
                SubCategory(name: "Sigorta Primi (BES)", icon: "shield.fill", colorHex: "#34C759"),
                SubCategory(name: "Banka Masrafı", icon: "percent", colorHex: "#636366"),
                SubCategory(name: "Verilen Borç", icon: "hand.raised.fill", colorHex: "#5AC8FA")
            ]
        )
    ]
}
