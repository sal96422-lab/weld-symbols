# AutoCAD Weld Symbols Toolbar

AutoLISP weld symbol toolbar for AutoCAD 2027.

This package adds commands and a toolbar for placing fillet weld symbols, then adding field weld, weld-all-around, and tail text items from toolbar buttons.

## Included Files

- `Install-WeldSymbols.bat` - one-click Windows installer.
- `Install-WeldSymbols.ps1` - installer script used by the BAT file.
- `weldsym_cmd.lsp` - main editable source file.
- `installed_weldsym_safe.lsp` - stable installed copy of the AutoLISP loader/tool.
- `weldsym.lsp` - helper/source copy.
- `weldsym.dcl` - dialog definition file.
- `WELDSYM.mnu` - AutoCAD menu/toolbar source.
- `weld*.bmp` - toolbar icon thumbnails.
- `type_images/` - weld type picker thumbnails.
- `README_STABLE.txt` - local stable-copy notes.

## One-Click Install

1. Close AutoCAD.
2. Download this repository as a ZIP from GitHub.
3. Extract the ZIP to a normal folder.
4. Double-click:

   ```text
   Install-WeldSymbols.bat
   ```

The installer finds AutoCAD support folders under `%APPDATA%\Autodesk`, copies all required files, creates layer-aware startup loading in `acaddoc.lsp`, and backs up any existing `acaddoc.lsp` before editing it.

After installing, open AutoCAD and run:

```text
WELDTOOLBAR
```

If AutoCAD reports a security warning, add the AutoCAD support folder to Trusted Locations and reload:

```lisp
(load (findfile "weldsym_safe.lsp"))
```

## Manual Install For AutoCAD 2027

1. Close AutoCAD.
2. Download this repository as a ZIP, or clone it with Git.
3. Open this AutoCAD support folder:

   ```text
   %APPDATA%\Autodesk\AutoCAD 2027\R26.0\enu\Support
   ```

4. Copy these files into that support folder:

   ```text
   weldsym_cmd.lsp
   installed_weldsym_safe.lsp
   weldsym.dcl
   WELDSYM.mnu
   weldsym_type_picker.ps1
   weldsym_type_picker_server.ps1
   type_images
   weldright16.bmp
   weldright32.bmp
   weldright64.bmp
   weldleft16.bmp
   weldleft32.bmp
   weldleft64.bmp
   weldfield16.bmp
   weldfield32.bmp
   weldfield64.bmp
   weldaround16.bmp
   weldaround32.bmp
   weldaround64.bmp
   weldtail16.bmp
   weldtail32.bmp
   weldtail64.bmp
   weldtail1-16.bmp
   weldtail1-32.bmp
   weldtail2-16.bmp
   weldtail2-32.bmp
   ```

5. In the support folder, rename `installed_weldsym_safe.lsp` to:

   ```text
   weldsym_safe.lsp
   ```

   Or copy `weldsym_cmd.lsp` directly as `weldsym_safe.lsp`.

6. In the same support folder, edit or create `acaddoc.lsp` and add this line:

   ```lisp
   (load (strcat (getenv "APPDATA") "/Autodesk/AutoCAD 2027/R26.0/enu/Support/weldsym_safe.lsp"))
   ```

7. Open AutoCAD.
8. If the toolbar does not appear automatically, type this command:

   ```text
   WELDTOOLBAR
   ```

## Main Commands

- `WELDTOOLBAR` - loads or refreshes the docked weld toolbar.
- `WELDRIGHT` - place a right-facing weld callout.
- `WELDLEFT` - place a left-facing weld callout.
- `WELDFIELD` - add the field weld flag to the last placed weld symbol.
- `WELDALLAROUND` - add the weld-all-around symbol to the last placed weld symbol.
- `WELDTAIL` - add tail geometry to the last placed weld symbol.
- `WELDTAILONE` - add one line of tail text.
- `WELDTAILTWO` - add two lines of tail text.

## Typical Workflow

1. Click `Weld Right` or `Weld Left` on the toolbar.
2. Pick the leader arrow point.
3. Pick the bend point.
4. Pick the reference line end, or right-click/press Enter to use the default reference length.
5. Use the toolbar buttons to add field weld, weld-all-around, tail, one-line tail text, or two-line tail text.

## Troubleshooting

If commands show as unknown, load the file manually once:

```lisp
(load (strcat (getenv "APPDATA") "/Autodesk/AutoCAD 2027/R26.0/enu/Support/weldsym_safe.lsp"))
```

If toolbar icons show as question marks, make sure every `weld*.bmp` file is copied into the same support folder as `weldsym_safe.lsp`, then restart AutoCAD and run `WELDTOOLBAR`.

If duplicate toolbars appear, close AutoCAD, reopen it, and run `WELDTOOLBAR` once.
