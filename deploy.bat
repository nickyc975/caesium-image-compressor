rmdir /s/y %2
windeployqt.exe "%1\Release\Caesium Image Compressor.exe" --dir %2 --release
copy /y "%1\Release\Caesium Image Compressor.exe" "%2\Caesium Image Compressor.exe"
copy /y "%1\libcaesium-prefix\src\libcaesium\target\x86_64-pc-windows-msvc\release\caesium.dll" "%2\caesium.dll"
copy /y "%1\libwinsparkle-prefix\src\libwinsparkle\x64\Release\WinSparkle.dll" "%2\WinSparkle.dll"
