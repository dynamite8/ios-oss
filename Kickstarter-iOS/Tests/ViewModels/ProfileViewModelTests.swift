import Foundation
import XCTest
import ReactiveCocoa
import Result
import Models
@testable import KsApi
@testable import Kickstarter_iOS
@testable import Library
@testable import ReactiveExtensions_TestHelpers
@testable import KsApi_TestHelpers
@testable import Models_TestHelpers

internal final class ProfileViewModelTests: TestCase {
  let vm = ProfileViewModel()
  let user = TestObserver<User, NoError>()
  let hasBackedProjects = TestObserver<Bool, NoError>()
  let goToProject = TestObserver<Project, NoError>()
  let goToRefTag = TestObserver<RefTag, NoError>()
  let showEmptyState = TestObserver<Bool, NoError>()

  internal override func setUp() {
    super.setUp()
    self.vm.outputs.user.observe(user.observer)
    self.vm.outputs.backedProjects.map { !$0.isEmpty }.observe(hasBackedProjects.observer)
    self.vm.outputs.goToProject.map { $0.0 }.observe(goToProject.observer)
    self.vm.outputs.goToProject.map { $0.1 }.observe(goToRefTag.observer)
    self.vm.outputs.showEmptyState.observe(showEmptyState.observer)
  }

  func testProjectCellPressed() {
    let project = ProjectFactory.live()
    self.vm.inputs.projectPressed(project)

    self.goToProject.assertValues([project], "Project emmitted.")
    self.goToRefTag.assertValues([RefTag.users], "RefTag =users emitted.")
  }

  func testUserWithBackedProjects() {
    let currentUser = UserFactory.user()

    AppEnvironment.login(AccessTokenEnvelope(accessToken: "deadbeef", user: currentUser))
    self.vm.inputs.viewWillAppear()
    self.scheduler.advance()

    self.user.assertValues([currentUser, currentUser], "Current user immediately emmitted and refreshed.")
    self.hasBackedProjects.assertValues([true])
    self.showEmptyState.assertValues([false])

    XCTAssertEqual(["Profile View My"], trackingClient.events)
  }

  func testUserWithNoProjects() {
    withEnvironment(apiService: MockService(fetchDiscoveryResponseCount: 0)) {
      AppEnvironment.login(AccessTokenEnvelope(accessToken: "deadbeef", user: UserFactory.user()))
      self.vm.inputs.viewWillAppear()
      self.scheduler.advance()
      self.hasBackedProjects.assertValues([false])
      self.showEmptyState.assertValues([true], "Empty state is shown for user with 0 backed projects.")
    }
  }
}