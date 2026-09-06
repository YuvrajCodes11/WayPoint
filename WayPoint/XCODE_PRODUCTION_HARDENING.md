# Xcode Production Hardening & Release Locking Guide
## WayPoint (RevenueCat #Shipaton 2026) — 100% Offline Air-Gapped Release

This guide outlines the exact build configuration settings and terminal commands required to lock down the **WayPoint** binary for production deployment. These steps ensure maximum binary compression, microsecond execution performance, and complete symbol stripping to prevent reverse-engineering or decompilation.

---

## 1. Configure Xcode Target Build Settings

In Xcode, select the **WayPoint** project in the Project Navigator, select the **WayPoint** target, navigate to **Build Settings**, and apply the following configuration for **Release**:

### Optimization Level
- **Swift Compiler - Code Generation -> Optimization Level (Release)**:
  `Fastest, Smallest [-O]` (`SWIFT_OPTIMIZATION_LEVEL = "-O"`)
- **Apple Clang - Code Generation -> Optimization Level (Release)**:
  `Fastest, Smallest [-Os]` (`GCC_OPTIMIZATION_LEVEL = "s"`)

### Deployment Postprocessing & Symbol Stripping
- **Deployment Postprocessing**: `YES` (`DEPLOYMENT_POSTPROCESSING = YES`)
- **Strip Linked Product**: `YES` (`STRIP_INSTALLED_PRODUCT = YES`)
- **Strip Style**: `All Symbols` (`STRIP_STYLE = all`)
- **Strip Swift Symbols**: `YES` (`STRIP_SWIFT_SYMBOLS = YES`)
- **Strip Debug Symbols During Copy**: `YES` (`COPY_PHASE_STRIP = YES`)
- **Symbols Hidden by Default**: `YES` (`GCC_SYMBOLS_PRIVATE_EXTERN = YES`)

---

## 2. Xcode Build Settings Configuration (xcconfig equivalent)

```ini
// Production Release Locking
SWIFT_OPTIMIZATION_LEVEL = -O
GCC_OPTIMIZATION_LEVEL = s
DEPLOYMENT_POSTPROCESSING = YES
STRIP_INSTALLED_PRODUCT = YES
STRIP_STYLE = all
STRIP_SWIFT_SYMBOLS = YES
COPY_PHASE_STRIP = YES
GCC_SYMBOLS_PRIVATE_EXTERN = YES
ENABLE_NS_ASSERTIONS = NO
```

---

## 3. Verify Binary Symbol Stripping via Terminal

After building the Release archive/bundle, execute the following commands in Terminal to verify zero decompilation leakage:

### A. Inspect Symbol Table (`nm`)
Run `nm` to confirm internal function names and graph algorithm symbols have been stripped:

```bash
# Path to your built app binary inside DerivedData or Archive
BINARY_PATH="$HOME/Library/Developer/Xcode/DerivedData/WayPoint-*/Build/Products/Release-iphoneos/WayPoint.app/WayPoint"

# Verify symbol stripping (should return 0 global symbols or empty output)
nm -g "$BINARY_PATH" | grep -E "(GraphRouter|BudgetGraphRouter|SecureVault)"
```

*Expected Result*: Empty output (no symbols matching `GraphRouter`, `BudgetGraphRouter`, or `SecureVault`).

### B. Verify Dynamic Dependencies & Symbols (`otool`)
Inspect exported symbols and shared library linkages:

```bash
otool -I -v "$BINARY_PATH"
```

*Expected Result*: Only system framework dynamic linkage references (e.g. `Security.framework`, `LocalAuthentication.framework`, `CoreGraphics.framework`). Zero app-level internal symbol definitions leaked.

### C. Manual Emergency Stripping (Optional)
If manual stripping is required on an unstripped staging binary:

```bash
strip -s -r "$BINARY_PATH"
```

---

## 4. Verification & Validation Checklist

- [x] Binary operates 100% air-gapped without remote endpoints or cellular fallback.
- [x] Optimization level set to `-O` for sub-millisecond Dijkstra pathfinding.
- [x] `STRIP_INSTALLED_PRODUCT = YES` enforced.
- [x] `nm` verification passes with zero leaked internal routing symbols.
