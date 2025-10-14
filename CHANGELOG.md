# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- **CRITICAL**: Corrected localStorage key for Qwen token extraction from `token` to `web_api_token`
  - Fixes automated authentication setup that was always failing
  - Users can now successfully extract bearer tokens via Playwright
  - Impact: HIGH - Unblocks automated setup workflow

### Changed
- **Repository Structure**: Comprehensive reorganization for better maintainability
  - Moved all test files to `tests/` with `unit/` and `integration/` subdirectories
  - Moved all documentation to `docs/` with `guides/`, `development/`, and `api/` subdirectories
  - Removed duplicate `extract_qwen_token.py` (functionality in `tests/integration/test_auth.py`)
  - Updated `scripts/setup.sh` to use new test paths
  - Added pytest markers and configuration for better test organization
  - Added comprehensive READMEs in tests/ and docs/ directories
  
### Added
- `tests/conftest.py` - Pytest configuration with custom markers
- `tests/README.md` - Complete test documentation
- `docs/README.md` - Documentation index with navigation
- `CHANGELOG.md` - This file for tracking changes
- `.backup/` directory - Safety backups of all modified files
- `DEPENDENCIES.md` - Dependency audit documentation

### Improved
- **Code Organization**: Root directory now clean with only essential files
- **Test Discovery**: Clear separation between fast unit tests and slower integration tests
- **Documentation**: Better organized with clear hierarchy and navigation
- **Developer Experience**: Easier to find relevant docs and tests
- **Maintainability**: Reduced clutter, better structure, follows best practices

## Previous Work

### [2025-10-13] - PR #8: Async Generator Fix
- Fixed `chat_completion()` return type to `Union[Dict, AsyncGenerator]`
- Split logic into `_non_stream_completion()` and `_stream_completion()` methods
- Proper await handling in `provider_factory.py`

### [2025-10-12] - Initial Implementation
- OpenAI-compatible API gateway for Qwen models
- Multi-provider support architecture
- Playwright-based authentication
- Docker deployment configuration
- Comprehensive API documentation

---

## Contributing

When contributing, please update this CHANGELOG:
- Add new entries under `[Unreleased]` section
- Use semantic versioning categories: Added, Changed, Deprecated, Removed, Fixed, Security
- Include impact level for fixes (HIGH/MEDIUM/LOW)
- Link to PR numbers where applicable

