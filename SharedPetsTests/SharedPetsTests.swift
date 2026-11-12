import Testing
@testable import SharedPets

struct SharedPetsTests {
    @Test func appModuleLoads() {
        #expect(SharedPetsApp.self == SharedPetsApp.self)
    }
}
