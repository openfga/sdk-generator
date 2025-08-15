# OpenFGA SDK Generator - AI Agent Instructions

## Repository Overview

This repository is the **OpenFGA SDK Generator**, the central tool responsible for generating client SDKs for the OpenFGA fine-grained authorization system. It transforms the OpenFGA OpenAPI v2 specification into language-specific client libraries using OpenAPI Generator CLI with custom templates and configurations.

## Core Purpose

- **Primary Function**: Generate consistent, high-quality client SDKs for multiple programming languages
- **Input**: OpenFGA OpenAPI v2 specification from the `openfga/api` repository
- **Output**: Language-specific SDKs published to package managers (npm, PyPI, NuGet, Maven Central, Go modules)
- **Supported Languages**: JavaScript, Go, .NET (C#), Python, Java

## Architecture & Build Process

### Key Components

1. **Makefile**: Main orchestration with language-specific build targets
2. **scripts/build_client.sh**: Core build script that merges configurations and executes generation
3. **config/common/**: Shared branding, metadata, and base configuration
4. **config/clients/{language}/**: Language-specific overrides, templates, and generator settings
5. **Docker Integration**: Uses containerized environments for consistent builds

### Build Flow

1. **Fetch OpenAPI Spec**: Downloads from `openfga/api` repository using configurable commit reference
2. **Apply Transformations**: 
   - Removes streaming endpoints (`/streamed-list-objects`, `/read-tuples`)
   - Renames `Object` to `FgaObject` to avoid language keyword conflicts
   - Strips `v1.` prefixes for cleaner APIs
3. **Merge Configurations**: Combines base config with language-specific overrides
4. **Generate SDK**: Runs OpenAPI Generator CLI with custom templates
5. **Post-Processing**: Language-specific formatting, linting, and fixes

## Configuration System

### Base Configuration (`config/common/config.base.json`)
- OpenFGA branding and metadata
- Common package information
- User agent templates
- Documentation URLs
- License and copyright information

### Language-Specific Overrides (`config/clients/{lang}/config.overrides.json`)
- Package names and versions
- Language-specific settings
- Custom file mappings
- Generator-specific options
- FOSSA compliance notice IDs

### Template System
- **Common Templates**: Shared across all languages in `config/common/files/`
- **Language Templates**: Custom mustache templates in `config/clients/{lang}/template/`
- **File Mapping**: Configurable destination paths and template types

## Development Guidelines for AI Agents

### When Making Changes

1. **Version Updates**: Always update `packageVersion` in language-specific `config.overrides.json`
2. **OpenAPI Changes**: Update `OPEN_API_REF` in Makefile when targeting new API versions
3. **Template Modifications**: Test against all supported languages, not just one
4. **Docker Dependencies**: Update Docker tags in Makefile when upgrading tools

### Configuration Patterns

- **Consistent Naming**: Follow `fga-{language}-sdk` pattern for output directories
- **Package Naming**: Use established conventions per language ecosystem
- **Version Synchronization**: Coordinate version bumps across related changes
- **Template Inheritance**: Leverage common templates before creating language-specific ones

### Testing & Validation

- **Build Verification**: Run `make test-all-clients` before major changes
- **Language-Specific Testing**: Use `make test-client-{language}` for targeted validation
- **Docker Environment**: All builds run in containerized environments for consistency
- **Integration Tests**: Some languages have additional integration test suites

### Common Modification Scenarios

1. **Adding New Language Support**:
   - Use `make setup-new-sdk` script
   - Create config directory structure
   - Define generator type and templates
   - Add Makefile targets

2. **API Schema Changes**:
   - Update OpenAPI transformations in build scripts
   - Verify template compatibility
   - Test generated code compilation
   - Update documentation

3. **Dependency Updates**:
   - Update Docker image tags in Makefile
   - Verify compatibility across all languages
   - Update any version-specific configurations

### File Structure Conventions

```
config/
├── common/                    # Shared configuration
│   ├── config.base.json      # Base OpenFGA metadata
│   └── files/                # Common template files
└── clients/{language}/       # Language-specific config
    ├── config.overrides.json # Language overrides
    ├── generator.txt         # OpenAPI generator type
    ├── .openapi-generator-ignore
    ├── CHANGELOG.md.mustache
    └── template/             # Custom templates
```

### Error Handling Patterns

- **Build Failures**: Check Docker container logs and generator output
- **Template Errors**: Validate mustache syntax and variable references
- **Post-Processing Issues**: Review language-specific sed commands and formatting tools
- **Version Conflicts**: Ensure consistent versioning across configuration files

### Security Considerations

- **API Keys**: Never hardcode credentials in templates or configurations
- **FOSSA Compliance**: Maintain compliance notice IDs for license tracking
- **Dependency Scanning**: Leverage language-specific vulnerability tools (govulncheck, npm audit, etc.)
- **Container Security**: Use official, tagged Docker images

### Performance Optimization

- **Parallel Builds**: Makefile supports concurrent language builds
- **Docker Layer Caching**: Leverage Docker BuildKit for faster builds
- **Incremental Generation**: Only regenerate when OpenAPI spec or templates change
- **Resource Management**: Clean up temporary directories and containers

## Language-Specific Notes

### JavaScript/TypeScript
- Uses Node.js with npm for package management
- Applies TypeScript-specific post-processing fixes
- Includes ESLint configuration and formatting

### Go
- Generates Go modules with proper module paths
- Includes golangci-lint configuration
- Supports OAuth2 client credentials flow

### .NET (C#)
- Targets .NET Standard for broad compatibility
- Uses MSBuild project structure
- Includes NuGet package metadata

### Python
- Uses modern Python packaging with pyproject.toml
- Includes asyncio support for async operations
- Applies Black formatting and Ruff linting

### Java
- Uses Gradle build system
- Includes Maven Central publishing configuration
- Supports both synchronous and asynchronous APIs

## Maintenance & Updates

### Regular Tasks
- **API Sync**: Update `OPEN_API_REF` when new OpenFGA API versions are released
- **Dependency Updates**: Keep Docker images and language tools current
- **Security Patches**: Monitor and update vulnerable dependencies
- **Documentation**: Keep README and examples synchronized with generated SDKs

### Release Process
- **Version Coordination**: Update all language versions consistently
- **Testing**: Run full test suite before releases
- **Tagging**: Use semantic versioning for SDK releases
- **Publishing**: Coordinate package manager releases across languages

This repository is critical infrastructure for the OpenFGA ecosystem. Changes should be thoroughly tested and coordinated across all supported languages to maintain consistency and reliability.
