using Godot;
using System;
using System.Runtime.InteropServices;

public partial class OverlayFunctions : Node
{
	[DllImport("user32.dll")]
	static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
	public long ActiveDraggingWindowID = -1;
	
	[DllImport("user32.dll")]
	static extern int GetWindowLong(IntPtr hWnd, int nIndex);
	
	[DllImport("user32.dll")]
	static extern int SetWindowLong(IntPtr hWnd, int nIndex, uint dwNewLong);
	
	// constants for SetClickThrough
	private const int GWL_EXSTYLE = -20;
	private const uint WS_EX_TRANSPARENT = 0x00000020;
	// Constants for SetWindowPos
	static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
	const uint SWP_NOSIZE = 0x0001;
	const uint SWP_NOMOVE = 0x0002;
	const uint SWP_NOACTIVATE = 0x0010; // Doesn't steal keyboard focus, just moves visual order
	const uint SWP_SHOWWINDOW = 0x0040;

	public void ForceWindowToTop(long windowId = 0)
	{
		IntPtr hWnd = (IntPtr)DisplayServer.WindowGetNativeHandle(DisplayServer.HandleType.WindowHandle, (int)windowId);
		// This forces the window to the top of the Z-order stack
		SetWindowPos(hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW | SWP_NOACTIVATE | 0x4000 | 0x0200);
	}
	
public void SetClickThrough(bool enabled, long windowId = 0)
{
	IntPtr hWnd = (IntPtr)DisplayServer.WindowGetNativeHandle(DisplayServer.HandleType.WindowHandle, (int)windowId);
	uint exStyle = (uint)GetWindowLong(hWnd, -20);

	// CRITICAL: WS_EX_LAYERED (0x80000) must be ON for passthrough to work
	// CRITICAL: WS_EX_TRANSPARENT is 0x20
	uint layered = 0x00080000;
	uint transparent = 0x00000020;

	if (enabled)
		SetWindowLong(hWnd, -20, exStyle | layered | transparent);
	else
		SetWindowLong(hWnd, -20, (exStyle | layered) & ~transparent);
}
	
}
