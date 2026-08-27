# Gym Companion Mobile App - Dependencies

## Core Dependencies

### State Management
- **flutter_riverpod** (^2.6.1) - Reactive state management and dependency injection
- **riverpod_annotation** (^2.3.3) - Code generation annotations for Riverpod

### HTTP & API
- **dio** (^5.4.0) - HTTP client with interceptors for authentication
- **http** (^1.2.0) - Additional HTTP utilities

### Local Storage
- **shared_preferences** (^2.2.2) - Persistent key-value storage (currently using in-memory token storage)

### JSON Serialization
- **json_annotation** (^4.9.0) - Annotations for JSON serialization
- **json_serializable** (^6.9.5) - Code generation for JSON serialization

### UI Components
- **flutter_svg** (^2.0.9) - SVG image rendering
- **fl_chart** (^0.66.0) - Chart library for progress visualization

## Development Dependencies

### Code Generation
- **build_runner** (^2.5.4) - Code generation runner
- **riverpod_generator** (^2.6.5) - Code generation for Riverpod providers
- **json_serializable** (^6.9.5) - JSON serialization code generation

### Testing
- **flutter_test** - Flutter testing framework
- **flutter_lints** - Dart linting rules

## Dependency Management

All dependencies are managed in `pubspec.yaml`. To add new dependencies:

```yaml
dependencies:
  package_name: ^version

dev_dependencies:
  build_runner: ^version
```

After modifying `pubspec.yaml`, run:
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```
