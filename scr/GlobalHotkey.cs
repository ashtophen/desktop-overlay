using Godot;
using System;
using System.Runtime.InteropServices;

public partial class GlobalHotkey : Node
{
	[DllImport("user32.dll")]
	private static extern short GetAsyncKeyState(int vKey);

	[Signal] public delegate void HotkeyPressedEventHandler();

	private const int VK_PERIOD = 0xBE; 
	private const int VK_MENU = 0x12;   
	
	private bool _wasPressed = false;

	public override void _Process(double delta)
	{
		// NO WINFORMS HERE - JUST USER32.DLL
		bool altDown = (GetAsyncKeyState(VK_MENU) & 0x8000) != 0;
		bool dotDown = (GetAsyncKeyState(VK_PERIOD) & 0x8000) != 0;

		if (altDown && dotDown)
		{
			if (!_wasPressed)
			{
				_wasPressed = true;
				EmitSignal(SignalName.HotkeyPressed);
				GD.Print("Hotkey Detected!");
			}
		}
		else
		{
			_wasPressed = false;
		}
	}
}
