// swiftlint:disable type_name
import Library
import Prelude
import Result
import XCTest
@testable import Kickstarter_Framework
@testable import KsApi

internal final class ProjectPamphletContentViewControllerTests: TestCase {
  private let cosmicSurgery = Project.cosmicSurgery
    |> Project.lens.photo.full .~ ""
    |> (Project.lens.creator.avatar • User.Avatar.lens.small) .~ ""

  override func setUp() {
    super.setUp()
    AppEnvironment.pushEnvironment(
      config: .template |> Config.lens.countryCode .~ self.cosmicSurgery.country.countryCode,
      mainBundle: NSBundle.framework
    )
  }

  override func tearDown() {
    super.tearDown()
    AppEnvironment.popEnvironment()
  }

  func testAllCategoryGroups() {
    let project = self.cosmicSurgery
      |> Project.lens.rewards .~ [self.cosmicSurgery.rewards.first!]
      |> Project.lens.state .~ .live

    let categories = [Category.art, Category.filmAndVideo, Category.games]
    let devices = [Device.phone4_7inch, Device.pad]

    combos(categories, devices).forEach { category, device in
      let categorizedProject = project |> Project.lens.category .~ category
      let vc = ProjectPamphletViewController.configuredWith(
        projectOrParam: .left(categorizedProject), refTag: nil
      )
      let (parent, _) = traitControllers(device: device, orientation: .portrait, child: vc)
      parent.view.frame.size.height = device == .pad ? 1_400 : 1_000

      FBSnapshotVerifyView(vc.view, identifier: "category_\(category.slug)_device_\(device)")
    }
  }

  func testNonBacker_LiveProject() {
    let project = self.cosmicSurgery
      |> Project.lens.state .~ .live
      |> Project.lens.stats.pledged .~ self.cosmicSurgery.stats.goal * 3/4

    combos(Language.allLanguages, [Device.phone4_7inch, Device.pad]).forEach { language, device in
      withEnvironment(language: language) {
        let vc = ProjectPamphletViewController.configuredWith(projectOrParam: .left(project), refTag: nil)
        let (parent, _) = traitControllers(device: device, orientation: .portrait, child: vc)
        parent.view.frame.size.height = device == .pad ? 2_300 : 2_200

        FBSnapshotVerifyView(vc.view, identifier: "lang_\(language)_device_\(device)")
      }
    }
  }

  func testNonBacker_SuccessfulProject() {
    let project = self.cosmicSurgery
      |> Project.lens.dates.stateChangedAt .~ 1234567890.0
      |> Project.lens.state .~ .successful

    Language.allLanguages.forEach { language in
      withEnvironment(language: language) {
        let vc = ProjectPamphletViewController.configuredWith(projectOrParam: .left(project), refTag: nil)
        let (parent, _) = traitControllers(device: .phone4_7inch, orientation: .portrait, child: vc)
        parent.view.frame.size.height = 1_750

        FBSnapshotVerifyView(vc.view, identifier: "lang_\(language)")
      }
    }
  }

  func testBacker_LiveProject() {
    let project = self.cosmicSurgery
      |> Project.lens.rewards %~ { rewards in [rewards[0], rewards[2]] }
      |> Project.lens.state .~ .live
      |> Project.lens.stats.pledged .~ self.cosmicSurgery.stats.goal * 3/4
      |> Project.lens.personalization.isBacking .~ true
      |> Project.lens.personalization.backing %~~ { _, project in
        .template
          |> Backing.lens.amount .~ (project.rewards.first!.minimum + 5)
          |> Backing.lens.rewardId .~ project.rewards.first?.id
          |> Backing.lens.reward .~ project.rewards.first
    }

    combos(Language.allLanguages, [Device.phone4_7inch, Device.pad]).forEach { language, device in
      withEnvironment(language: language) {

        let vc = ProjectPamphletViewController.configuredWith(projectOrParam: .left(project), refTag: nil)
        let (parent, _) = traitControllers(device: device, orientation: .portrait, child: vc)
        parent.view.frame.size.height = device == .pad ? 1_600 : 1_350

        FBSnapshotVerifyView(vc.view, identifier: "lang_\(language)_device_\(device)")
      }
    }
  }

  func testBacker_LiveProject_NoReward() {
    let project = self.cosmicSurgery
      |> Project.lens.rewards %~ { rewards in [rewards[0]] }
      |> Project.lens.state .~ .live
      |> Project.lens.personalization.isBacking .~ true
      |> Project.lens.personalization.backing %~~ { _, project in
        .template
          |> Backing.lens.amount .~ 5
          |> Backing.lens.rewardId .~ nil
          |> Backing.lens.reward .~ nil
    }

    Language.allLanguages.forEach { language in
      withEnvironment(apiService: MockService(fetchProjectResponse: project), language: language) {

        let vc = ProjectPamphletViewController.configuredWith(projectOrParam: .left(project), refTag: nil)
        let (parent, _) = traitControllers(device: .phone4_7inch, orientation: .portrait, child: vc)
        parent.view.frame.size.height = 1_200

        FBSnapshotVerifyView(vc.view, identifier: "lang_\(language)")
      }
    }
  }

  func testBacker_SuccessfulProject() {
    let project = self.cosmicSurgery
      |> Project.lens.rewards %~ { rewards in [rewards[0], rewards[2]] }
      |> Project.lens.dates.stateChangedAt .~ 1234567890.0
      |> Project.lens.state .~ .successful
      |> Project.lens.personalization.isBacking .~ true
      |> Project.lens.personalization.backing %~~ { _, project in
        .template
          |> Backing.lens.amount .~ (project.rewards.first!.minimum + 5)
          |> Backing.lens.rewardId .~ project.rewards.first?.id
          |> Backing.lens.reward .~ project.rewards.first
    }

    combos(Language.allLanguages, [Device.phone4_7inch, Device.pad]).forEach { language, device in
      withEnvironment(language: language) {

        let vc = ProjectPamphletViewController.configuredWith(projectOrParam: .left(project), refTag: nil)
        let (parent, _) = traitControllers(device: device, orientation: .portrait, child: vc)
        parent.view.frame.size.height = device == .pad ? 1_600 : 1_350

        FBSnapshotVerifyView(vc.view, identifier: "lang_\(language)_device_\(device)")
      }
    }
  }

  func testBackerOfSoldOutReward() {
    let soldOutReward = self.cosmicSurgery.rewards.filter { $0.remaining == 0 }.first!
    let project = self.cosmicSurgery
      |> Project.lens.rewards .~ [soldOutReward]
      |> Project.lens.state .~ .live
      |> Project.lens.stats.pledged .~ self.cosmicSurgery.stats.goal * 3/4
      |> Project.lens.personalization.isBacking .~ true
      |> Project.lens.personalization.backing %~~ { _, project in
        .template
          |> Backing.lens.amount .~ (project.rewards.first!.minimum + 5)
          |> Backing.lens.rewardId .~ project.rewards.first?.id
          |> Backing.lens.reward .~ project.rewards.first
    }

    let vc = ProjectPamphletViewController.configuredWith(projectOrParam: .left(project), refTag: nil)
    let (parent, _) = traitControllers(device: .phone4_7inch, orientation: .portrait, child: vc)
    parent.view.frame.size.height = 1_000

    FBSnapshotVerifyView(vc.view)
  }

  func testFailedProject() {
    let project = self.cosmicSurgery
      |> Project.lens.dates.stateChangedAt .~ 1234567890.0
      |> Project.lens.state .~ .failed

    Language.allLanguages.forEach { language in
      withEnvironment(language: language) {
        let vc = ProjectPamphletViewController.configuredWith(projectOrParam: .left(project), refTag: nil)
        let (parent, _) = traitControllers(device: .phone4_7inch, orientation: .portrait, child: vc)
        parent.view.frame.size.height = 1_700

        FBSnapshotVerifyView(vc.view, identifier: "lang_\(language)")
      }
    }
  }
}