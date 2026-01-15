# **DangerSwift: Automate Code Reviews in Swift Projects with Github Actions**  

DangerSwift is a plugin for [Danger](https://danger.systems/swift) tailored to Swift projects. It helps automate code review tasks, ensuring your pull requests meet your team’s standards. With DangerSwift, you can enforce linting rules, track test coverage, detect large file additions, and much more — all integrated into your CI/CD pipeline.  


<img width="966" alt="debug swift" src="https://github.com/user-attachments/assets/1356a78b-c3ed-473d-bd65-e10656baed06" />


Key Features:
- Written in Swift, with full support for the language's ecosystem.
- Flexible DSL for writing custom rules.
- Works seamlessly with popular CI services like GitHub Actions, Bitrise, and more.
- Actively maintained and community-driven.

Get started with automating your code reviews today!

# Example
<img width="1048" alt="example" src="https://github.com/user-attachments/assets/37a74baa-d22e-48e1-a4af-566c56064509" />


### 1. See this example: [Example](https://github.com/DebugSwift/DebugSwift/pull/113) :

<br>


## Example: `.github/workflows/danger.yml`


```yml
name: CI and Danger

on:
  pull_request:
    branches:
      - main
      - develop

jobs:
  ci:
    name: CI Build and Tests
    permissions: write-all
    runs-on: macos-14

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Set up Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '16.4'

      - name: Install CocoaPods
        run: |
          cd Example
          pod install
      
      - name: Setup Danger
        run: |
          git clone https://github.com/DebugSwift/DangerSwift && rm -rf DangerSwift/.git Readme.md
          mv DangerSwift/* .
      
      - name: Test Stage
        run: |
          cd Example
          bundle install
          bundle exec fastlane test

      - name: Danger Stage
        run: |
          brew install danger/tap/danger-js
          swift build
          swift run danger-swift ci --verbose
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          DANGER_GITHUB_API_TOKEN: ${{ secrets.GITHUB_TOKEN }}

```

<br><br>


## Example: `.swiftlint.yml`

```yml
included:
  - DebugSwift <Optional: Your package name>

excluded:
  - Tests

analyzer_rules:
  - unused_declaration
  - unused_import

opt_in_rules:
  - all

disabled_rules:
  - anonymous_argument_in_multiline_closure
  - anyobject_protocol
  - closure_body_length
  - conditional_returns_on_newline
  - convenience_type
  - discouraged_optional_collection
  - explicit_acl
  - explicit_enum_raw_value
  - explicit_top_level_acl
  - explicit_type_interface
  - file_types_order
  - final_test_case
  - force_unwrapping
  - function_default_parameter_at_end
  - implicit_return
  - implicitly_unwrapped_optional
  - indentation_width
  - inert_defer
  - missing_docs
  - multiline_arguments
  - multiline_arguments_brackets
  - multiline_function_chains
  - multiline_literal_brackets
  - multiline_parameters
  - multiline_parameters_brackets
  - no_extension_access_modifier
  - no_fallthrough_only
  - no_grouping_extension
  - no_magic_numbers
  - one_declaration_per_file
  - prefer_nimble
  - prefer_self_in_static_references
  - prefixed_toplevel_constant
  - redundant_self_in_closure
  - required_deinit
  - self_binding
  - static_over_final_class
  - shorthand_argument
  - sorted_enum_cases
  - strict_fileprivate
  - switch_case_on_newline
  - todo
  - trailing_closure
  - type_contents_order
  - unused_capture_list
  - vertical_whitespace_between_cases

attributes:
  always_on_line_above:
    - "@ConfigurationElement"
    - "@OptionGroup"
    - "@RuleConfigurationDescriptionBuilder"
    
identifier_name:
  excluded:
    - id
large_tuple: 3

number_separator:
  minimum_length: 5

file_name:
  excluded:
    - Exports.swift
    - GeneratedTests.swift
    - RuleConfigurationMacros.swift
    - SwiftSyntax+SwiftLint.swift
    - TestHelpers.swift

unneeded_override:
  affect_initializers: true

balanced_xctest_lifecycle: &unit_test_configuration
  test_parent_classes:
    - SwiftLintTestCase
    - XCTestCase

empty_xctest_method: *unit_test_configuration
single_test_class: *unit_test_configuration

function_body_length: 60
type_body_length: 400
```


<br><br>


## Example: `Dangerfile.swift`

```swift
// MARK: Imports

import Danger
import DangerSwiftCoverage
import DangerXCodeSummary
import Foundation

// MARK: Validate

Validator.shared.validate()

// MARK: Lint

SwiftLint.lint(configFile: ".swiftlint.yml")

// MARK: Validation rules

internal class Validator {
    // MARK: Lifecycle
    // Private initializer and shared instance for Validator.

    private init() {}
    internal static let shared = Validator()
    private var danger = Danger()

    // MARK: Properties
    // Properties related to PR details and changes.

    private lazy var additions = danger.github.pullRequest.additions!
    private lazy var deletions = danger.github.pullRequest.deletions!
    private lazy var changedFiles = danger.github.pullRequest.changedFiles!

    private lazy var modified = danger.git.modifiedFiles
    private lazy var editedFiles = modified + danger.git.createdFiles
    private lazy var prTitle = danger.github.pullRequest.title

    private lazy var branchHeadName = danger.github.pullRequest.head.ref
    private lazy var branchBaseName = danger.github.pullRequest.base.ref

    // Methods
    // Methods for various validation checks.

    internal func validate() {
        checkSize()
        checkDescription()
        checkUnitTest()
        checkTitle()
        checkAssignee()
        checkModifiedFiles()
        checkFails()

        logResume()
    }
}

internal class DescriptionValidator {
    // MARK: Lifecycle
    // Private initializer and shared instance for DescriptionValidator.

    private init() {}
    internal static let shared = DescriptionValidator()
    private var danger = Danger()

    // MARK: Properties
    // Property to store the PR body.

    private lazy var body = danger.github.pullRequest.body ?? ""

    // Methods
    // Method to validate PR description.

    internal func validate() {
        let message = "PR does not have a description. You must provide a description of the changes made."

        guard !body.isEmpty else {
            fail(message)
            return
        }
    }
}

internal class UnitTestValidator {
    // MARK: Lifecycle
    // Private initializer and shared instance for UnitTestValidator.

    private init() {}
    internal static let shared = UnitTestValidator()
    private var danger = Danger()

    // Methods
    // Methods for unit test validation.

    internal func validate() {
        checkUnitTestSummary()
        checkUnitTestCoverage()
    }
}

// MARK: Validator Methods
// Extension with methods for Validator class.

fileprivate extension Validator {
    func checkSize() {
        if (additions + deletions) > ValidationRules.bigPRThreshold {
            let message =
            """
            The size of the PR seems relatively large. \
            If possible, in the future if the PR contains multiple changes, split each into a separate PR. \
            This helps in faster and easier review.
            """
            warn(message)
        }
    }

    func checkDescription() {
        DescriptionValidator.shared.validate()
    }

    func checkUnitTest() {
        UnitTestValidator.shared.validate()
    }

    func checkTitle() {
        let result = prTitle.range(
            of: #"\[[A-zÀ-ú0-9 ]*\][A-zÀ-ú0-9- ]+"#,
            options: .regularExpression
        ) != nil

        if !result {
            let message = "The PR title should be: [<i>Feature or Flow</i>] <i>What flow was done</i>"
            warn(message)
        }
    }

    func checkAssignee() {
        if danger.github.pullRequest.assignee == nil {
            warn("Please assign yourself to the PR.")
        }
    }

    func checkModifiedFiles() {
        if changedFiles > ValidationRules.maxChangedFiles {
            let message =
            """
            PR contains too many changed files. If possible, next time try to split into smaller features.
            """
            warn(message)
        }
    }

    func checkFails() {
        if !danger.fails.isEmpty {
            _ = danger.utils.exec("touch Danger-has-fails.swift")
        }
    }

    func logResume() {
        let overview =
        """
        The PR added \(additions) and removed \(deletions) lines. \(changedFiles) file(s) changed.
        """

        // TODO: - Add PR documentation link
        let seeOurDocumentation =
        """
        Documentation: \
        <a href=''> \
        Link</a>
        """

        // message(seeOurDocumentation)
        message(overview)
    }
}

// MARK: Constants
// Constants related to validation rules.

private enum ValidationRules {
    static let maxChangedFiles = 20
    static let bigPRThreshold = 3000
}

// MARK: Extensions
// Extension with additional file-related methods.

fileprivate extension Danger.File {
    var isInSources: Bool { hasPrefix("Sources/") }
    var isInTests: Bool { hasPrefix("Tests/") }

    var isSourceFile: Bool {
        hasSuffix(".swift") || hasSuffix(".h") || hasSuffix(".m")
    }

    var isSwiftPackageDefintion: Bool {
        hasPrefix("Package") && hasSuffix(".swift")
    }

    var isDangerfile: Bool {
        self == "Dangerfile.swift"
    }
}

// MARK: UnitTestValidator Methods
// Extension with methods for UnitTestValidator class.

fileprivate extension UnitTestValidator {
    func checkUnitTestSummary() {
        let file = "build/reports/errors.json"
        if FileManager.default.fileExists(atPath: file) {
            let summary = XCodeSummary(filePath: file) { result in
                result.category != .warning
            }
            summary.report()
        }
    }

    func checkUnitTestCoverage() {
        Coverage.xcodeBuildCoverage(
            .xcresultBundle("Example/fastlane/test_output/Example.xcresult"),
            minimumCoverage: 70,
            excludedTargets: ["DangerSwiftCoverageTests.xctest"]
        )
    }
}
```



## 2. Contribute
We welcome contributions to improve this project! To contribute, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make your changes and commit them.
4. Push your changes to your forked repository.
5. Open a pull request to the main repository.

Please ensure that your code follows the project's coding conventions and includes appropriate tests.

## 3. License
This project is licensed under the MIT License. You can find the full license text in the [LICENSE](https://github.com/DebugSwift/DangerSwift/blob/main/LICENSE) file.

