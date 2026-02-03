# Contributing to terraform-aws-storage-management-datadog

First off, thanks for taking the time to contribute!

## Getting Started

1. Fork the repository
2. Clone your fork
3. Create a feature branch (`git checkout -b feature/my-feature`)
4. Make your changes
5. Run `terraform fmt` to format your code
6. Run `terraform validate` to check for errors
7. Commit your changes (`git commit -am 'Add my feature'`)
8. Push to the branch (`git push origin feature/my-feature`)
9. Open a Pull Request

## Development

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- Datadog API and App keys

### Testing

Before submitting a PR, ensure:

1. `terraform fmt -check -recursive` passes
2. `terraform validate` passes in the root module and examples
3. Documentation is updated if you've changed variables, outputs, or behavior

## Code Style

- Follow [Terraform style conventions](https://developer.hashicorp.com/terraform/language/syntax/style)
- Use meaningful variable and resource names
- Add comments for complex logic
- Update README.md if you add new features or change behavior

## Reporting Bugs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md) and include:

- Terraform version
- Provider versions
- Module version
- Steps to reproduce
- Expected vs actual behavior

## Feature Requests

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md) and describe:

- The problem you're trying to solve
- Your proposed solution
- Any alternatives you've considered

## License

By contributing, you agree that your contributions will be licensed under the Apache 2.0 License.
