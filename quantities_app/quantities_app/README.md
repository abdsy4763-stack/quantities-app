# حصر الكميات المعماري — Flutter port

Android port of the Excel/VBA workbook. The calculation engine (`lib/engine`) is a
line-by-line port of the VBA (`GenerateBlockTakeoff_WithWaste_Core`,
`WriteAggregatedTable`, `CalculateProjectTotal`), verified against golden data.

## Build
    flutter create . --platforms=android --org com.quantities --project-name quantities_app
    flutter pub get
    flutter test
    flutter build apk --release        # build/app/outputs/flutter-apk/app-release.apk

Or push to GitHub: the workflow `.github/workflows/build-apk.yml` runs the tests and
builds the APK for you (Actions -> Build APK -> download artifact).

## Data
`assets/data/seed.json` was exported from the workbook: 852 items (Database), the
10 picker lists, and the waste rates. `tool/reference_engine.py` regenerates
`test/golden.json` (run from the project root).
