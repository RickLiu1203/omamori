//
//  SafetyViewModelToastTests.swift
//  omamoriTests
//

import Testing
@testable import omamori

@MainActor
@Suite struct SafetyViewModelToastTests {

    @Test func showToastSetsMessage() async {
        let vm = SafetyViewModel()
        vm.showToast("Test error")
        #expect(vm.toastMessage == "Test error")
    }

    @Test(.timeLimit(.minutes(1))) func toastMessageClearsAfterThreeSeconds() async {
        let vm = SafetyViewModel()
        vm.showToast("Test error")
        #expect(vm.toastMessage != nil)

        try? await Task.sleep(for: .seconds(3.5))
        #expect(vm.toastMessage == nil)
    }
}
