import Foundation

/// Estimates an approximate (latitude, longitude) for a `TimeZone` without
/// network calls or location permissions. v1 uses a small lookup of the
/// most common timezone identifiers plus a coarse GMT-offset fallback. The
/// result is intentionally rough — accuracy is sufficient for ambient
/// sunset estimation, not navigation.
enum TimeZoneLocationEstimator {
    struct Coordinates: Equatable {
        let latitude: Double
        let longitude: Double
    }

    static func estimate(for timeZone: TimeZone = .current, now: Date = Date()) -> Coordinates {
        if let hit = lookup[timeZone.identifier] {
            return hit
        }

        // Fall back: derive longitude from GMT offset, default latitude based
        // on the hemisphere hint in the timezone identifier.
        let offsetHours = Double(timeZone.secondsFromGMT(for: now)) / 3600.0
        let longitude = max(min(offsetHours * 15.0, 180.0), -180.0)
        let latitude = isLikelySouthernHemisphere(timeZone.identifier) ? -33.0 : 40.0
        return Coordinates(latitude: latitude, longitude: longitude)
    }

    private static func isLikelySouthernHemisphere(_ identifier: String) -> Bool {
        for prefix in southernHemispherePrefixes where identifier.hasPrefix(prefix) {
            return true
        }
        return southernHemisphereIdentifiers.contains(identifier)
    }

    private static let southernHemispherePrefixes: [String] = [
        "Australia/",
        "Antarctica/",
        "Pacific/Auckland",
        "Pacific/Chatham",
        "Pacific/Fiji",
        "Pacific/Norfolk"
    ]

    private static let southernHemisphereIdentifiers: Set<String> = [
        "America/Argentina/Buenos_Aires",
        "America/Sao_Paulo",
        "America/Santiago",
        "America/La_Paz",
        "America/Lima",
        "America/Asuncion",
        "Africa/Johannesburg",
        "Africa/Windhoek",
        "Africa/Maputo",
        "Africa/Harare",
        "Indian/Antananarivo",
        "Indian/Mauritius"
    ]

    /// Lookup of common timezones to representative city coordinates.
    /// Coordinates are city-center approximations; sufficient for sunset
    /// estimation within tens of minutes of true local sunset.
    private static let lookup: [String: Coordinates] = [
        // Americas
        "America/New_York":       .init(latitude: 40.71, longitude: -74.00),
        "America/Chicago":        .init(latitude: 41.88, longitude: -87.63),
        "America/Denver":         .init(latitude: 39.74, longitude: -104.99),
        "America/Phoenix":        .init(latitude: 33.45, longitude: -112.07),
        "America/Los_Angeles":    .init(latitude: 34.05, longitude: -118.24),
        "America/Anchorage":      .init(latitude: 61.22, longitude: -149.90),
        "America/Toronto":        .init(latitude: 43.65, longitude: -79.38),
        "America/Vancouver":      .init(latitude: 49.28, longitude: -123.12),
        "America/Mexico_City":    .init(latitude: 19.43, longitude: -99.13),
        "America/Sao_Paulo":      .init(latitude: -23.55, longitude: -46.63),
        "America/Argentina/Buenos_Aires": .init(latitude: -34.61, longitude: -58.38),
        "America/Santiago":       .init(latitude: -33.45, longitude: -70.67),

        // Europe
        "Europe/London":          .init(latitude: 51.51, longitude: -0.13),
        "Europe/Paris":           .init(latitude: 48.86, longitude: 2.35),
        "Europe/Berlin":          .init(latitude: 52.52, longitude: 13.41),
        "Europe/Madrid":          .init(latitude: 40.42, longitude: -3.70),
        "Europe/Rome":            .init(latitude: 41.90, longitude: 12.50),
        "Europe/Amsterdam":       .init(latitude: 52.37, longitude: 4.90),
        "Europe/Stockholm":       .init(latitude: 59.33, longitude: 18.07),
        "Europe/Helsinki":        .init(latitude: 60.17, longitude: 24.94),
        "Europe/Athens":          .init(latitude: 37.98, longitude: 23.73),
        "Europe/Moscow":          .init(latitude: 55.76, longitude: 37.62),
        "Europe/Istanbul":        .init(latitude: 41.01, longitude: 28.98),

        // Asia
        "Asia/Tokyo":             .init(latitude: 35.68, longitude: 139.69),
        "Asia/Shanghai":          .init(latitude: 31.23, longitude: 121.47),
        "Asia/Hong_Kong":         .init(latitude: 22.32, longitude: 114.17),
        "Asia/Singapore":         .init(latitude: 1.35, longitude: 103.82),
        "Asia/Seoul":             .init(latitude: 37.57, longitude: 126.98),
        "Asia/Kolkata":           .init(latitude: 22.57, longitude: 88.36),
        "Asia/Dubai":             .init(latitude: 25.20, longitude: 55.27),
        "Asia/Bangkok":           .init(latitude: 13.76, longitude: 100.50),
        "Asia/Jakarta":           .init(latitude: -6.20, longitude: 106.85),

        // Oceania
        "Australia/Sydney":       .init(latitude: -33.87, longitude: 151.21),
        "Australia/Melbourne":    .init(latitude: -37.81, longitude: 144.96),
        "Australia/Perth":        .init(latitude: -31.95, longitude: 115.86),
        "Pacific/Auckland":       .init(latitude: -36.85, longitude: 174.76),

        // Africa
        "Africa/Johannesburg":    .init(latitude: -26.20, longitude: 28.05),
        "Africa/Cairo":           .init(latitude: 30.04, longitude: 31.24),
        "Africa/Lagos":           .init(latitude: 6.52, longitude: 3.38)
    ]
}
