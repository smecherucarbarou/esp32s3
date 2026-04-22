if (-not ("Audio.VolumeControl" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

namespace Audio
{
    enum EDataFlow
    {
        eRender,
        eCapture,
        eAll,
        EDataFlow_enum_count
    }

    enum ERole
    {
        eConsole,
        eMultimedia,
        eCommunications,
        ERole_enum_count
    }

    [Flags]
    enum CLSCTX : uint
    {
        INPROC_SERVER = 0x1,
        INPROC_HANDLER = 0x2,
        LOCAL_SERVER = 0x4,
        REMOTE_SERVER = 0x10,
        ALL = INPROC_SERVER | INPROC_HANDLER | LOCAL_SERVER | REMOTE_SERVER
    }

    [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IMMDeviceEnumerator
    {
        int EnumAudioEndpoints(EDataFlow dataFlow, int dwStateMask, out object ppDevices);
        int GetDefaultAudioEndpoint(EDataFlow dataFlow, ERole role, out IMMDevice ppEndpoint);
        int GetDevice(string pwstrId, out IMMDevice ppDevice);
        int RegisterEndpointNotificationCallback(IntPtr pClient);
        int UnregisterEndpointNotificationCallback(IntPtr pClient);
    }

    [Guid("D666063F-1587-4E43-81F1-B948E807363F"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IMMDevice
    {
        int Activate(ref Guid iid, CLSCTX dwClsCtx, IntPtr pActivationParams, [MarshalAs(UnmanagedType.Interface)] out object ppInterface);
        int OpenPropertyStore(int stgmAccess, out object ppProperties);
        int GetId([MarshalAs(UnmanagedType.LPWStr)] out string ppstrId);
        int GetState(out int pdwState);
    }

    [Guid("5CDF2C82-841E-4546-9722-0CF74078229A"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IAudioEndpointVolume
    {
        int RegisterControlChangeNotify(IntPtr pNotify);
        int UnregisterControlChangeNotify(IntPtr pNotify);
        int GetChannelCount(out uint pnChannelCount);
        int SetMasterVolumeLevel(float fLevelDB, ref Guid pguidEventContext);
        int SetMasterVolumeLevelScalar(float fLevel, ref Guid pguidEventContext);
        int GetMasterVolumeLevel(out float pfLevelDB);
        int GetMasterVolumeLevelScalar(out float pfLevel);
        int SetChannelVolumeLevel(uint nChannel, float fLevelDB, ref Guid pguidEventContext);
        int SetChannelVolumeLevelScalar(uint nChannel, float fLevel, ref Guid pguidEventContext);
        int GetChannelVolumeLevel(uint nChannel, out float pfLevelDB);
        int GetChannelVolumeLevelScalar(uint nChannel, out float pfLevel);
        int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, ref Guid pguidEventContext);
        int GetMute([MarshalAs(UnmanagedType.Bool)] out bool pbMute);
        int GetVolumeStepInfo(out uint pnStep, out uint pnStepCount);
        int VolumeStepUp(ref Guid pguidEventContext);
        int VolumeStepDown(ref Guid pguidEventContext);
        int QueryHardwareSupport(out uint pdwHardwareSupportMask);
        int GetVolumeRange(out float pflVolumeMindB, out float pflVolumeMaxdB, out float pflVolumeIncrementdB);
    }

    [ComImport]
    [Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
    class MMDeviceEnumeratorComObject
    {
    }

    public static class VolumeControl
    {
        public static void SetVolume(float level)
        {
            if (level < 0.0f || level > 1.0f)
                throw new ArgumentOutOfRangeException("level");

            var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;

            IMMDevice device;
            Marshal.ThrowExceptionForHR(
                enumerator.GetDefaultAudioEndpoint(EDataFlow.eRender, ERole.eMultimedia, out device)
            );

            Guid iid = typeof(IAudioEndpointVolume).GUID;
            object obj;
            Marshal.ThrowExceptionForHR(
                device.Activate(ref iid, CLSCTX.ALL, IntPtr.Zero, out obj)
            );

            var volume = (IAudioEndpointVolume)obj;
            Guid guid = Guid.Empty;

            Marshal.ThrowExceptionForHR(volume.SetMute(false, ref guid));
            Marshal.ThrowExceptionForHR(volume.SetMasterVolumeLevelScalar(level, ref guid));
        }
    }
}
"@
}

if (-not ("WinAPI.NativeMethods" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

namespace WinAPI
{
    public static class NativeMethods
    {
        [DllImport("user32.dll", SetLastError=true)]
        public static extern void keybd_event(byte bVk, byte bScan, int dwFlags, int dwExtraInfo);

        public const int KEYEVENTF_KEYUP = 0x0002;
        public const byte VK_VOLUME_MUTE = 0xAD;
        public const byte VK_VOLUME_DOWN = 0xAE;
        public const byte VK_VOLUME_UP   = 0xAF;
    }
}
"@
}

function Show-VolumeOSD {
    [WinAPI.NativeMethods]::keybd_event([WinAPI.NativeMethods]::VK_VOLUME_UP, 0, 0, 0)
    Start-Sleep -Milliseconds 80
    [WinAPI.NativeMethods]::keybd_event([WinAPI.NativeMethods]::VK_VOLUME_UP, 0, [WinAPI.NativeMethods]::KEYEVENTF_KEYUP, 0)

    Start-Sleep -Milliseconds 120

    [WinAPI.NativeMethods]::keybd_event([WinAPI.NativeMethods]::VK_VOLUME_DOWN, 0, 0, 0)
    Start-Sleep -Milliseconds 80
    [WinAPI.NativeMethods]::keybd_event([WinAPI.NativeMethods]::VK_VOLUME_DOWN, 0, [WinAPI.NativeMethods]::KEYEVENTF_KEYUP, 0)
}

# Descarcam arsenalul in TEMP
$u1='https://raw.githubusercontent.com/smecherucarbarou/esp32s3/main/kingu/poza.jpeg'
$u2='https://raw.githubusercontent.com/smecherucarbarou/esp32s3/main/kingu/king.mp3'
$p1="$env:TEMP\p.jpg"; $p2="$env:TEMP\m.mp3"
$wc=New-Object Net.WebClient
$wc.DownloadFile($u1,$p1)
$wc.DownloadFile($u2,$p2)

# Setam wallpaper-ul sa straluceasca valoarea
$w=@'
[DllImport("user32.dll")]public static extern int SystemParametersInfo(int a,int b,string c,int d);
'@
$t=Add-Type -MemberDefinition $w -Name W -Namespace U -PassThru
$t::SystemParametersInfo(20,0,$p1,3)

# Executam manevra ta de aur pentru volum
[Audio.VolumeControl]::SetVolume(0.69)
Show-VolumeOSD
Start-Sleep -Milliseconds 150
[Audio.VolumeControl]::SetVolume(0.69)

# Dam drumul la lautari
$m=New-Object -ComObject WMPlayer.OCX
$m.URL=$p2
$m.controls.play()
while($m.playState -ne 1){Start-Sleep -s 1}
