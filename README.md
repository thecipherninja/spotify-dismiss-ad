<h1 align="center"><img src="./icon.ico" width="28" height="28" alt="icon" />Spotify Dismiss Ad</h1>

[![download32](https://custom-icon-badges.demolab.com/badge/-Download%2032--bit-8DC740?style=for-the-badge&logo=download&logoColor=white)](https://github.com/thecipherninja/spotify-dismiss-ad/releases/download/v1.0/SpotifyDismissAd_U32.exe)
[![download64](https://custom-icon-badges.demolab.com/badge/-Download%2064--bit-8DC740?style=for-the-badge&logo=download&logoColor=white)](https://github.com/thecipherninja/spotify-dismiss-ad/releases/download/v1.0/SpotifyDismissAd_U64.exe)

## Description
A simple desktop application that mutes or skips (by relaunching Spotify) Spotify advertisements while music is playing.<br/>

Main motivation was to build something useful at least for myself. This hobby project introduced me to Windows APIs and desktop app automation and development using AutoHotkey.

> [!WARNING] 
> This is a non-serious project created for personal use and educational purposes. Use it at your own risk!

## Dependencies
- **Spotify** (latest version, 32/64-bit): [Download here](https://www.spotify.com/de-en/download/windows/)
- **Windows 10** (32/64-bit)
- **AutoHotkey v1.1.37.02 (optional)** (32/64-bit): [Download here](https://www.autohotkey.com/docs/v1/Tutorial.htm#s11)
  - Alternatively, use the included zip archive or download it from [AutoHotkey Releases](https://github.com/AutoHotkey/AutoHotkey/releases/tag/v1.1.37.02).
- **Git (optional)** [Download here](https://git-scm.com/downloads/win)

> [!NOTE]
> May work on other Spotify, Windows, or AutoHotkey versions upon testing.

## Steps to Run the Application

1. **Get source (Optional)**

 - **From GitHub**

    ```bat
    git clone --recurse-submodules https://github.com/thecipherninja/spotify-dismiss-ad.git
    ```

 - **From zip archive**

    [Download](https://github.com/thecipherninja/spotify-dismiss-ad/archive/refs/heads/main.zip)

    *Command Prompt*:
    ```bat
    tar -xf spotify-dismiss-ad-main.zip
    ```
    *PowerShell*:
    ```bat
    Expand-Archive -Path .\spotify-dismiss-ad-main.zip -DestinationPath .\ -Force
    ```

2. **Extract AHK files from zip (Optional)**

 - **Verify zip file integrity**

   *Command Prompt*:
   ```bat
   certutil -hashfile AutoHotkey_1.1.37.02.zip SHA256 | findstr /i "6F3663F7CDD25063C8C8728F5D9B07813CED8780522FD1F124BA539E2854215F" >nul && echo True || echo False
   ```
   *PowerShell*:
   ```bat
   (Get-FileHash .\AutoHotkey_1.1.37.02.zip -Algorithm SHA256).Hash -eq "6F3663F7CDD25063C8C8728F5D9B07813CED8780522FD1F124BA539E2854215F"
   ```

 - **Extract files**

   *Command Prompt*:
   ```bat
   mkdir AutoHotkey_1.1.37.02 && tar -xf AutoHotkey_1.1.37.02.zip -C AutoHotkey_1.1.37.02
   ```
   *PowerShell*:
   ```bat
   Expand-Archive -Path .\AutoHotkey_1.1.37.02.zip -Force
   ```

3. **Run the Application**

> [!NOTE]
> You don't need to have AutoHotkey installed to run compiled executables.

   - **From Windows Explorer**:
        Double-click the `.ahk` script or the compiled `.exe` file. Alternatively, right-click the file and select **Run Script**.
        Get already compiled .exe files here: [32-bit](https://github.com/thecipherninja/spotify-dismiss-ad/releases/download/v1.0/SpotifyDismissAd_U32.exe) / [64-bit](https://github.com/thecipherninja/spotify-dismiss-ad/releases/download/v1.0/SpotifyDismissAd_U64.exe)

   - **From Command Line**:

     **Script**

        *32-bit*
       ```bat
       .\AutoHotkey_1.1.37.02\AutoHotkeyU32.exe .\SpotifyDismissAd.ahk
       ```
        *64-bit*
       ```bat
       .\AutoHotkey_1.1.37.02\AutoHotkeyU64.exe .\SpotifyDismissAd.ahk
       ```

     **Compiled Executable**

        *32-bit*
       ```bat
       .\Bin\SpotifyDismissAd_U32.exe
       ```
        *64-bit*
       ```bat
       .\Bin\SpotifyDismissAd_U64.exe
       ```

## Building the Executable

For more details, refer to the [AutoHotkey documentation](https://www.autohotkey.com/docs/v1/Scripts.htm#ahk2exe).  

  *32-bit*
  ```cmd
  .\AutoHotkey_1.1.37.02\Compiler\Ahk2Exe.exe /in .\SpotifyDismissAd.ahk /base ".\AutoHotkey_1.1.37.02\Compiler\Unicode 32-bit.bin"
  ```
  *64-bit*
  ```cmd
  .\AutoHotkey_1.1.37.02\Compiler\Ahk2Exe.exe /in .\SpotifyDismissAd.ahk /base ".\AutoHotkey_1.1.37.02\Compiler\Unicode 64-bit.bin"
  ```

Compiled executables will be located in the `.\Bin` directory.

## License
[MIT License](./LICENSE)

## References and Attributions
- ![muted.png](./muted.png) <a href="https://www.flaticon.com/free-icons/silent" title="silent icons">Silent icons created by Freepik - Flaticon</a>
- ![unmuted.png](./unmuted.png) <a href="https://www.flaticon.com/free-icons/audio" title="audio icons">Audio icons created by Freepik - Flaticon</a>
- [Masojar's VA library](https://github.com/Masonjar13/AHK-Library)
- [Lexiko's VA library](https://github.com/ahkscript/VistaAudio)
- [AutoHotkey Documentation](https://www.autohotkey.com/docs/v1/)
- [Windows API Documentation](https://learn.microsoft.com/en-us/windows/win32/api/)

