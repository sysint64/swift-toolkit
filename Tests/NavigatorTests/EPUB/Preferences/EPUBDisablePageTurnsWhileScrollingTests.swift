//
//  Copyright 2026 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

@testable import ReadiumNavigator
import ReadiumShared
import Testing

@Suite("EPUB disablePageTurnsWhileScrolling") struct EPUBDisablePageTurnsWhileScrollingTests {
    private func resolve(
        defaults: EPUBDefaults = EPUBDefaults(),
        preferences: EPUBPreferences = EPUBPreferences()
    ) -> Bool {
        EPUBSettings(
            preferences: preferences,
            defaults: defaults,
            metadata: Metadata(title: "Fake title")
        ).disablePageTurnsWhileScrolling
    }

    @Test("is false without preference or default")
    func falseByDefault() {
        #expect(resolve() == false)
    }

    @Test("falls back on the default value")
    func defaultValue() {
        #expect(resolve(defaults: EPUBDefaults(disablePageTurnsWhileScrolling: true)) == true)
    }

    @Test("preference takes precedence over the default value")
    func preferenceOverridesDefault() {
        #expect(resolve(
            defaults: EPUBDefaults(disablePageTurnsWhileScrolling: true),
            preferences: EPUBPreferences(disablePageTurnsWhileScrolling: false)
        ) == false)
        #expect(resolve(
            defaults: EPUBDefaults(disablePageTurnsWhileScrolling: false),
            preferences: EPUBPreferences(disablePageTurnsWhileScrolling: true)
        ) == true)
    }

    @Test("merging keeps the other value when set")
    func merging() {
        let base = EPUBPreferences(disablePageTurnsWhileScrolling: true)
        #expect(base.merging(EPUBPreferences()).disablePageTurnsWhileScrolling == true)
        #expect(base.merging(EPUBPreferences(disablePageTurnsWhileScrolling: false)).disablePageTurnsWhileScrolling == false)
    }

    @Test("is a shared preference")
    func sharedPreference() {
        let prefs = EPUBPreferences(disablePageTurnsWhileScrolling: true)
        #expect(prefs.filterSharedPreferences().disablePageTurnsWhileScrolling == true)
        #expect(prefs.filterPublicationPreferences().disablePageTurnsWhileScrolling == nil)
    }

    @Test("deprecated configuration property is forwarded to the defaults")
    @MainActor
    func deprecatedConfiguration() {
        #expect(EPUBNavigatorViewController.Configuration().defaults.disablePageTurnsWhileScrolling == nil)
        #expect(EPUBNavigatorViewController.Configuration(disablePageTurnsWhileScrolling: true).defaults.disablePageTurnsWhileScrolling == true)
        #expect(EPUBNavigatorViewController.Configuration(
            defaults: EPUBDefaults(disablePageTurnsWhileScrolling: true),
            disablePageTurnsWhileScrolling: false
        ).defaults.disablePageTurnsWhileScrolling == false)
    }
}
