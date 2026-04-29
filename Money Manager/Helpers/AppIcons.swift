import SwiftUI

/// SVG path strings for all app icons.
/// Render with a 24×24 viewBox, stroke width 2, round linecap/linejoin.
///
/// Usage:
///   Image(systemName: "fork.knife")          // prefer SF Symbols when available
///   AppIcons.path(AppIcons.Category.food)    // custom path via Path shape
enum AppIcons {

    // MARK: - Category icons
    enum Category {
        static let food           = "M18 2a2 2 0 012 2v16l-2-2-2 2V4a2 2 0 012-2zM6 2v6M6 8a4 4 0 004 4v10M10 2v4"
        static let coffee         = "M17 8h1a4 4 0 010 8h-1M3 8h14v9a4 4 0 01-4 4H7a4 4 0 01-4-4V8zM6 1v3M10 1v3M14 1v3"
        static let groceries      = "M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4zM3 6h18M16 10a4 4 0 01-8 0"
        static let dining         = "M3 11l19-9-9 19-2-8-8-2z"
        static let transport      = "M5 17H3a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v5a2 2 0 01-2 2H5zm0 0a2 2 0 104 0 2 2 0 00-4 0zm12 0a2 2 0 104 0 2 2 0 00-4 0z"
        static let fuel           = "M3 22V9l7-7 7 7v13H3zM10 22V15h4v7M5 22h14M14 9h2a2 2 0 012 2v2a2 2 0 01-2 2h-2"
        static let transit        = "M8 6v6M16 6v6M2 12h20M12 2a7 7 0 017 7v11H5V9a7 7 0 017-7zM5 19a2 2 0 002 2h10a2 2 0 002-2M8 19v2M16 19v2"
        static let flights        = "M21 16v-2l-8-5V3.5A1.5 1.5 0 0011.5 2v0A1.5 1.5 0 0010 3.5V9l-8 5v2l8-2.5V19l-2 1.5V22l3.5-1 3.5 1v-1.5L13 19v-5.5l8 2.5z"
        static let housing        = "M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
        static let health         = "M22 12h-4l-3 9L9 3l-3 9H2"
        static let pharmacy       = "M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"
        static let gym            = "M6.5 6.5h11M6.5 17.5h11M3 12h18M3 4v16M21 4v16"
        static let yoga           = "M12 2a5 5 0 110 10A5 5 0 0112 2zM12 12v10M7 17l5-5 5 5"
        static let shopping       = "M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"
        static let clothing       = "M20.38 3.46L16 2a4 4 0 01-8 0L3.62 3.46a2 2 0 00-1.34 2.23l.58 3.57a1 1 0 00.99.84H6v10c0 1.1.9 2 2 2h8a2 2 0 002-2V10h2.15a1 1 0 00.99-.84l.58-3.57a2 2 0 00-1.34-2.23z"
        static let electronics    = "M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z"
        static let entertainment  = "M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664zM21 12a9 9 0 11-18 0 9 9 0 0118 0z"
        static let music          = "M9 18V5l12-2v13M9 18a3 3 0 11-6 0 3 3 0 016 0zm12-2a3 3 0 11-6 0 3 3 0 016 0z"
        static let gaming         = "M21 6H3a2 2 0 00-2 2v8a2 2 0 002 2h18a2 2 0 002-2V8a2 2 0 00-2-2zM10 14v-4M8 12h4M16 12h.01M19 12h.01"
        static let books          = "M4 19.5A2.5 2.5 0 016.5 17H20M4 19.5A2.5 2.5 0 014 22h16v-5H6.5M4 19.5V4a2 2 0 012-2h12v9H6.5a2.5 2.5 0 00-2.5 2.5z"
        static let travel         = "M12 22s-8-4.5-8-11.8A8 8 0 0112 2a8 8 0 018 8.2c0 7.3-8 11.8-8 11.8zM12 13a3 3 0 100-6 3 3 0 000 6z"
        static let hotels         = "M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2zM9 22V12h6v10"
        static let subscriptions  = "M13 2L3 14h9l-1 8 10-12h-9l1-8z"
        static let streaming      = "M15 10l4.553-2.069A1 1 0 0121 8.87v6.263a1 1 0 01-1.447.894L15 14M3 8h12v8H3z"
        static let bills          = "M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
        static let phone          = "M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
        static let electricity    = "M13 10V3L4 14h7v7l9-11h-7z"
        static let insurance      = "M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"
        static let education      = "M12 14l9-5-9-5-9 5 9 5zm0 0l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0112 20.055a11.952 11.952 0 01-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z"
        static let courses        = "M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
        static let investments    = "M7 12l3-3 3 3 4-4M8 21l4-4 4 4M3 4h18M4 4h16v12a1 1 0 01-1 1H5a1 1 0 01-1-1V4z"
        static let salary         = "M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
        static let savings        = "M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"
        static let personalCare   = "M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z"
        static let haircut        = "M14.121 14.121L19 19M5 3l4 4m0 0l4 4m-4-4l4-4M9 7L5 3m0 0a2 2 0 102.828 2.828"
        static let pets           = "M20.25 7.5l-.625 10.632a2.25 2.25 0 01-2.247 2.118H6.622a2.25 2.25 0 01-2.247-2.118L3.75 7.5M10 11.25h4M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z"
        static let gifts          = "M20 12v10H4V12M22 7H2v5h20V7zM12 22V7M12 7H7.5a2.5 2.5 0 010-5C11 2 12 7 12 7zM12 7h4.5a2.5 2.5 0 000-5C13 2 12 7 12 7z"
        static let work           = "M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
        static let freelance      = "M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
        static let atm            = "M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"
        static let taxes          = "M9 14l6-6m-5.5.5h.01m4.99 5h.01M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16l3.5-2 3.5 2 3.5-2 3.5 2zM10 8.5a.5.5 0 11-1 0 .5.5 0 011 0zm5 5a.5.5 0 11-1 0 .5.5 0 011 0z"
        static let donation       = "M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
        static let baby           = "M14 9V5a3 3 0 00-3-3l-4 9v11h11.28a2 2 0 002-1.7l1.38-9a2 2 0 00-2-2.3H14z"
        static let misc           = "M5 12h.01M12 12h.01M19 12h.01M6 12a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0z"
    }

    // MARK: - UI / Nav icons
    enum UI {
        static let home         = "M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
        static let transactions = "M4 6h16M4 10h16M4 14h16M4 18h16"
        static let groups       = "M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"
        static let settings     = "M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065zM15 12a3 3 0 11-6 0 3 3 0 016 0z"
        static let add          = "M12 5v14M5 12h14"
        static let back         = "M19 12H5M5 12l7 7M5 12l7-7"
        static let chevron      = "M9 5l7 7-7 7"
        static let search       = "M21 21l-4.35-4.35M17 11A6 6 0 115 11a6 6 0 0112 0z"
        static let edit         = "M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"
        static let delete       = "M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6"
        static let sync         = "M4 4v5h5M20 20v-5h-5M4 9a8 8 0 0115.3-3M20 15a8 8 0 01-15.3 3"
        static let budget       = "M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
        static let recurring    = "M4 4v5h5M20 20v-5h-5M4 9a8.003 8.003 0 0115.3-3M20 15a8.003 8.003 0 01-15.3 3"
        static let categories   = "M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"
        static let currency     = "M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
        static let export       = "M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1M7 10l5 5 5-5M12 15V3"
        static let warningIcon  = "M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0zM12 9v4M12 17h.01"
        static let settle       = "M3 12h18M3 12l4-4M3 12l4 4M21 12l-4-4M21 12l-4 4"
        static let profile      = "M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2M12 11a4 4 0 100-8 4 4 0 000 8z"
        static let logout       = "M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"
        static let check        = "M5 13l4 4L19 7"
        static let close        = "M6 18L18 6M6 6l12 12"
        static let more         = "M5 12h.01M12 12h.01M19 12h.01"
    }

    // MARK: - Category tint colors (design-spec palette)
    // Single-appearance colors — intentional brand swatches, not semantic tokens.
    // For income/expense/warning use AppColors instead.
    enum CategoryColor {
        static let teal   = Color("CatTeal",   bundle: .main)
        static let red    = Color("CatRed",    bundle: .main)
        static let green  = Color("CatGreen",  bundle: .main)
        static let orange = Color("CatOrange", bundle: .main)
        static let purple = Color("CatPurple", bundle: .main)
        static let blue   = Color("CatBlue",   bundle: .main)
        static let pink   = Color("CatPink",   bundle: .main)
        static let indigo = Color("CatIndigo", bundle: .main)
        static let sky    = Color("CatSky",    bundle: .main)
        static let yellow = Color("CatYellow", bundle: .main)
        static let mint   = Color("CatMint",   bundle: .main)
        static let coral  = Color("CatCoral",  bundle: .main)
        static let brown  = Color("CatBrown",  bundle: .main)
        static let gray   = Color("CatGray",   bundle: .main)
        static let dark   = Color("CatDark",   bundle: .main)
        static let gold   = Color("CatGold",   bundle: .main)

        static let all: [Color] = [
            teal, red, green, orange, purple, blue,
            pink, indigo, sky, yellow, mint, coral,
            brown, gray, dark, gold
        ]
    }
}
