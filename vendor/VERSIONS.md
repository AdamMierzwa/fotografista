# Pinned dependency versions

Fotografista is pinned to specific, verified dependency versions. This file
exists so that a future build can be reproduced exactly, even if upstream
moves on.

Licence terms for these dependencies are in [`../THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md).

---

## Graphics32

| | |
|---|---|
| Version | **3.0** (`Graphics32Version = '3.0'` in `GR32.pas`) |
| Upstream | <https://github.com/graphics32/graphics32> |
| Obtained | 2026-08-01, extracted from the upstream archive |
| Files included | `Source/` only - 246 files |
| Manifest SHA-256 | `1dc5e2b21ce7fb769f5caaaf92e4a43406a9228cd828408846bd0f8a8610dcc4` |

### Why pinned by content hash and not by commit

The archive was extracted without version-control metadata, so there is no
upstream commit hash to record. The tree SHA-256 above is the substitute: it
pins the exact bytes that this build was verified against, which is stronger
than a branch name and equally reproducible.

### Verifying the pin

From the repository root, in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File tools\mankist_graphics32.ps1
```

The script normalises line endings to LF before hashing and sorts paths
ordinally, so it yields the same manifest on a fresh clone, on Windows with a
different locale, and on Linux. Both outputs must read `plikow: 246` and the
SHA-256 above.

### Units actually consumed

Only three Graphics32 units appear in the project's `uses` clauses. The
remaining units are reached transitively through `uses` inside Graphics32
itself.

| Unit | Used in |
|---|---|
| `GR32` | `uConvolution.pas`, `uMipMap.pas`, `fMain.pas` |
| `GR32.Blur` | `uConvolution.pas`, `uMipMap.pas` |
| `GR32_Resamplers` | `uMipMap.pas` |

The statically reachable closure from those three is 93 units within
`Source/`. A previous successful Win64 build produced 78 `GR32*.dcu` files.

`Source/` is self-contained: it needs only `GR32.inc`, `Clipper.inc`,
`GR32_Compiler.inc` and `GR32_PngCompilerSwitches.inc`, all of which are inside
it. Nothing outside `Source/` is required to compile.

---

## fpdf

| | |
|---|---|
| Component | fpdf (FPDF-Pascal) |
| Location | `fpdf.pas` |
| Upstream | <https://github.com/Projeto-ACBr-Oficial/FPDF-Pascal> |
| Copyright | Copyright (C) 2023 Projeto ACBr - Daniel Simões de Almeida |
| License | MIT |
| Used in | `fMain.pas` (PDF export) |

Not version-pinned beyond the upstream release. The file carries no internal
version constant, so it is identified by its copyright year and upstream
repository.