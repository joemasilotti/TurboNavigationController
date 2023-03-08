import Turbo
@testable import TurboNavigator
import XCTest

/// Tests are written in the following format:
/// test_currentContext_givenContext_givenPresentation_modifiers_result()
/// See the README for a more visually pleasing table.
final class TurboNavigatorTests: XCTestCase {
    private var navigator: TurboNavigator!
    private var navigationController: TestableNavigationController!
    private var modalNavigationController: TestableNavigationController!
    private let window = UIWindow()

    override func setUp() {
        navigationController = TestableNavigationController()
        modalNavigationController = TestableNavigationController()

        navigator = TurboNavigator(
            delegate: EmptyDelegate(),
            navigationController: navigationController,
            modalNavigationController: modalNavigationController
        )

        pushInitialViewControllersOnNavigationController()
        loadNavigationControllerInWindow()
    }

    func test_default_default_default_pushesOnMainStack() {
        navigator.route(VisitProposal(path: "/one"))
        XCTAssertEqual(navigationController.viewControllers.count, 2)
        XCTAssert(navigationController.viewControllers.last is VisitableViewController)

        navigator.route(VisitProposal(path: "/two"))
        XCTAssertEqual(navigationController.viewControllers.count, 3)
        XCTAssert(navigationController.viewControllers.last is VisitableViewController)
    }

    func test_default_default_default_visitingSamePage_replacesOnMainStack() {
        navigator.route(VisitProposal(path: "/one"))
        XCTAssertEqual(navigationController.viewControllers.count, 2)

        navigator.route(VisitProposal(path: "/one"))
        XCTAssertEqual(navigationController.viewControllers.count, 2)
    }

    func test_default_default_default_visitingPreviousPage_popsAndVisitsOnMainStack() {
        navigator.route(VisitProposal(path: "/one"))
        XCTAssertEqual(navigationController.viewControllers.count, 2)

        navigator.route(VisitProposal(path: "/two"))
        XCTAssertEqual(navigationController.viewControllers.count, 3)

        navigator.route(VisitProposal(path: "/one"))
        XCTAssertEqual(navigationController.viewControllers.count, 2)
    }

    func test_default_default_default_replaceAction_replacesOnMainStack() {
        navigator.route(VisitProposal(action: .replace))

        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssert(navigationController.viewControllers.last is VisitableViewController)
    }

    func test_default_default_replace_replacesOnMainStack() {
        navigationController.pushViewController(UIViewController(), animated: false)
        XCTAssertEqual(navigationController.viewControllers.count, 2)

        navigator.route(VisitProposal(presentation: .replace))

        XCTAssertEqual(navigationController.viewControllers.count, 2)
        XCTAssert(navigationController.viewControllers.last is VisitableViewController)
    }

    func test_default_modal_default_presentsModal() {
        navigator.route(VisitProposal(context: .modal))

        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertEqual(modalNavigationController.viewControllers.count, 1)
        XCTAssert(navigationController.presentedViewController === modalNavigationController)
        XCTAssert(modalNavigationController.viewControllers.last is VisitableViewController)
    }

    func test_default_modal_replace_presentsModal() {
        navigator.route(VisitProposal(context: .modal, presentation: .replace))

        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertEqual(modalNavigationController.viewControllers.count, 1)
        XCTAssert(navigationController.presentedViewController === modalNavigationController)
        XCTAssert(modalNavigationController.viewControllers.last is VisitableViewController)
    }

    func test_modal_default_default_dismissesModalThenPushesOnMainStack() {
        navigator.route(VisitProposal(context: .modal))
        XCTAssert(navigationController.presentedViewController === modalNavigationController)

        navigator.route(VisitProposal())
        XCTAssert(navigationController.dismissWasCalled)
        XCTAssertEqual(navigationController.viewControllers.count, 2)
    }

    func test_modal_default_replace_dismissesModalThenReplacedOnMainStack() {
        navigator.route(VisitProposal(context: .modal))
        XCTAssert(navigationController.presentedViewController === modalNavigationController)

        navigator.route(VisitProposal(presentation: .replace))
        XCTAssert(navigationController.dismissWasCalled)
        XCTAssertEqual(navigationController.viewControllers.count, 1)
    }

    func test_modal_modal_default_pushesOnModalStack() {
        navigator.route(VisitProposal(path: "/one", context: .modal))
        XCTAssertEqual(modalNavigationController.viewControllers.count, 1)

        navigator.route(VisitProposal(path: "/two", context: .modal))
        XCTAssertEqual(modalNavigationController.viewControllers.count, 2)
    }

    func test_modal_modal_default_replaceAction_pushesOnModalStack() {
        navigator.route(VisitProposal(path: "/one", context: .modal))
        XCTAssertEqual(modalNavigationController.viewControllers.count, 1)

        navigator.route(VisitProposal(path: "/two", action: .replace, context: .modal))
        XCTAssertEqual(modalNavigationController.viewControllers.count, 1)
    }

    func test_modal_modal_replace_pushesOnModalStack() {
        navigator.route(VisitProposal(path: "/one", context: .modal))
        XCTAssertEqual(modalNavigationController.viewControllers.count, 1)

        navigator.route(VisitProposal(path: "/two", context: .modal, presentation: .replace))
        XCTAssertEqual(modalNavigationController.viewControllers.count, 1)
    }

    func test_default_any_pop_popsOffMainStack() {
        navigator.route(VisitProposal())
        XCTAssertEqual(navigationController.viewControllers.count, 2)

        navigator.route(VisitProposal(presentation: .pop))
        XCTAssertEqual(navigationController.viewControllers.count, 1)
    }

    func test_modal_any_pop_popsOffModalStack() {
        navigator.route(VisitProposal(path: "/one", context: .modal))
        navigator.route(VisitProposal(path: "/two", context: .modal))
        XCTAssertEqual(modalNavigationController.viewControllers.count, 2)

        navigator.route(VisitProposal(presentation: .pop))
        XCTAssertFalse(navigationController.dismissWasCalled)
        XCTAssertEqual(modalNavigationController.viewControllers.count, 1)
    }

    func test_modal_any_pop_exactlyOneModal_dismissesModal() {
        navigator.route(VisitProposal(path: "/one", context: .modal))
        XCTAssertEqual(modalNavigationController.viewControllers.count, 1)

        navigator.route(VisitProposal(presentation: .pop))
        XCTAssertTrue(navigationController.dismissWasCalled)
    }

    func test_any_any_clearAll_dismissesModalThenPopsToRootOnMainStack() {
        let rootController = UIViewController()
        navigationController.viewControllers = [rootController, UIViewController(), UIViewController()]
        XCTAssertEqual(navigationController.viewControllers.count, 3)

        navigator.route(VisitProposal(presentation: .clearAll))
        XCTAssertTrue(navigationController.dismissWasCalled)
        XCTAssertEqual(navigationController.viewControllers, [rootController])
    }

    func test_any_any_replaceRoot_dismissesModalThenReplacedRootOnMainStack() {
        let rootController = UIViewController()
        navigationController.viewControllers = [rootController, UIViewController(), UIViewController()]
        XCTAssertEqual(navigationController.viewControllers.count, 3)

        navigator.route(VisitProposal(presentation: .replaceRoot))
        XCTAssertTrue(navigationController.dismissWasCalled)
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssert(navigationController.viewControllers.last is VisitableViewController)
    }

    // Set an initial controller to simulate a populated navigation stack.
    private func pushInitialViewControllersOnNavigationController() {
        navigationController.pushViewController(UIViewController(), animated: false)
        modalNavigationController.pushViewController(UIViewController(), animated: false)
    }

    // Simulate a "real" app so presenting view controllers works under test.
    private func loadNavigationControllerInWindow() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        navigationController.loadViewIfNeeded()
    }
}

// MARK: - TurboNavigationDelegate

private class EmptyDelegate: TurboNavigationDelegate {
    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {}
}

// MARK: - VisitProposal extension

private extension VisitProposal {
    init(path: String = "", action: VisitAction = .advance, context: Navigation.Context = .default, presentation: Navigation.Presentation = .default) {
        let url = URL(string: "https://example.com")!.appendingPathComponent(path)
        let options = VisitOptions(action: action, response: nil)
        let properties: PathProperties = [
            "context": context.rawValue,
            "presentation": presentation.rawValue
        ]
        self.init(url: url, options: options, properties: properties)
    }
}