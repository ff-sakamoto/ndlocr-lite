# ocr.py を x64 Windows スタンドアロン DLL としてビルドする (Nuitka)
# 実行: powershell -ExecutionPolicy Bypass -File build_exe.ps1
#
# 出力:
#   ocr.dist\ocr.exe      - 上記を自己展開する onefile コンテナ (単体配布用)
#   ocr.dist\ocr.dist\       - standalone 展開フォルダ (ocr.exe + 依存 DLL 群)
#
# 前提: pip install zstandard  (onefile 圧縮に必要)

$ErrorActionPreference = "Stop"
$python = "C:\Users\fanfa\.pyenv\pyenv-win\versions\3.10.5\python.exe"

Set-Location $PSScriptRoot

Write-Host "[INFO] Nuitka ビルド開始: ocr.py -> ocr.dist\ocr.exe"

& $python -m nuitka `
    --standalone `
    --output-filename=ocr.exe `
    --output-dir=ocr.dist `
    --windows-console-mode=disable `
    --include-windows-runtime-dlls=auto `
    --include-data-dir=model=model `
    --include-data-dir=config=config `
    --nofollow-import-to=sympy `
    --nofollow-import-to=pandas `
    --nofollow-import-to=tkinter `
    --nofollow-import-to=flet `
    --nofollow-import-to=matplotlib `
    --nofollow-import-to=IPython `
    --nofollow-import-to=notebook `
    --nofollow-import-to=torch `
    --jobs=12 `
    ocr.py

if ($LASTEXITCODE -eq 0) {
    $dllSize = [math]::Round((Get-Item "ocr.dist\ocr.exe").Length / 1MB, 1)
    Write-Host "[SUCCESS] ビルド完了"
    Write-Host "  ocr.dist\ocr.exe  : ${dllSize} MB (onefile 配布用)"
    Write-Host "  ocr.dist\ocr.dist\    : standalone 展開フォルダ"
} else {
    Write-Host "[ERROR] ビルド失敗 (終了コード: $LASTEXITCODE)"
    exit $LASTEXITCODE
}
