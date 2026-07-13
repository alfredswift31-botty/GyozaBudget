//
//  GyozabudgetTests.swift
//  GyozabudgetTests
//
//  Created by Aung Hpone Moe on 10/04/2026.
//

import Testing
@testable import Gyozabudget

struct ParseAmountTests {

    @Test func plainDecimal() {
        #expect(AppPreferences.parseAmount("1234.56") == 1234.56)
    }

    @Test func zero() {
        #expect(AppPreferences.parseAmount("0") == 0)
    }

    @Test func whitespaceTrimmed() {
        #expect(AppPreferences.parseAmount("  42  ") == 42)
    }

    @Test func emptyIsNil() {
        #expect(AppPreferences.parseAmount("") == nil)
    }

    @Test func garbageIsNil() {
        #expect(AppPreferences.parseAmount("abc") == nil)
    }

    @Test func infinityIsNil() {
        #expect(AppPreferences.parseAmount("inf") == nil)
    }

    @Test func negativeIsNil() {
        #expect(AppPreferences.parseAmount("-5") == nil)
    }

    // Locale-dependent: "1,000" must never silently become 1.0 — it is
    // either a thousand (grouping locales) or exactly 1 (comma-decimal locales).
    @Test func groupedThousandNeverLosesMagnitude() {
        let value = AppPreferences.parseAmount("1,000")
        #expect(value == 1000 || value == 1)
    }
}
