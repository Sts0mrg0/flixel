package flixel.input.gamepad;

import flash.Lib;
import flixel.FlxG;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.gamepad.FlxGamepadID;
import flixel.input.gamepad.FlxGamepad;
import flixel.util.FlxDestroyUtil;

#if FLX_OPENFL_JOYSTICK_API
import openfl.events.JoystickEvent;
#end

#if (flash11_8 || next)
import flash.ui.GameInput;
import flash.ui.GameInputDevice;
import flash.events.GameInputEvent;
#end

/**
 * Manages gamepad input
 * @author Zaphod
 */
class FlxGamepadManager implements IFlxInputManager
{
	/**
	 * The first accessed gamepad - can be null!
	 */
	public var firstActive:FlxGamepad;
	/**
	 * The last accessed gamepad - can be null!
	 */
	public var lastActive:FlxGamepad;
	
	/**
	 * A counter for the number of active gamepads
	 */
	public var numActiveGamepads(get, null):Int;
	
	/**
	 * While you can have each joystick use a custom dead zone, setting this will 
	 * set every gamepad to use this deadzone.
	 */
	public var globalDeadZone(default, set):Float = 0;
	
	/**
	 * Stores all gamepads - can have null entries, but index matches event.device
	 */
	private var _gamepads:Array<FlxGamepad> = [];
	/**
	 * Stores all gamepads - no null entries, but index does *not* match event.device
	 */
	private var _activeGamepads:Array<FlxGamepad> = [];
	
	#if (flash11_8 || next)
	/**
	 * GameInput needs to be statically created, otherwise GameInput.numDevices will be zero during construction.
	 */
	private static var _gameInput:GameInput = new GameInput();
	#end
	
	/**
	 * Returns a FlxGamepad with the specified ID or null if none was found.
	 * E.g. if there are 4 gamepads connected, they will have the IDs 0-3.
	 */
	public inline function getByID(GamepadID:Int):FlxGamepad
	{
		return _activeGamepads[GamepadID];
	}
	
	private function removeByID(GamepadID:Int):Void
	{
		var gamepad:FlxGamepad = _gamepads[GamepadID];
		if (gamepad != null)
		{
			FlxDestroyUtil.destroy(gamepad);
			_gamepads[GamepadID] = null;
			
			var i = _activeGamepads.indexOf(gamepad);
			if (i != -1)
			{
				_activeGamepads[i] = null;
			}
		}
		
		if (lastActive == gamepad)
			lastActive = null;
		
		if (firstActive == gamepad)
			firstActive = null;
	}
	
	private function createByID(GamepadID:Int, ?Model:GamepadModel):FlxGamepad
	{
		var gamepad:FlxGamepad = _gamepads[GamepadID];
		if (gamepad == null)
		{
			gamepad = new FlxGamepad(GamepadID, globalDeadZone, Model);
			_gamepads[GamepadID] = gamepad;
			
			//fill the first "empty spot" in the array
			var nullFound:Bool = false;
			for (i in 0..._activeGamepads.length)
			{
				if (_activeGamepads[i] == null)
				{
					_activeGamepads[i] = gamepad;
					nullFound = true;
					break;
				}
			}
			
			if (!nullFound)
			{
				_activeGamepads.push(gamepad);
			}
			
			lastActive = gamepad;
			if (firstActive == null)
			{
				firstActive = gamepad;
			}
		}
		return gamepad;
	}
	
	/**
	 * Get array of ids for gamepads with any pressed buttons or moved Axis, Ball and Hat.
	 * 
	 * @param	IDsArray	optional array to fill with ids
	 * @return	array filled with active gamepad ids
	 */
	public function getActiveGamepadIDs(?IDsArray:Array<Int>):Array<Int>
	{
		if (IDsArray == null)
		{
			IDsArray = [];
		}
		
		for (gamepad in _gamepads)
		{
			if ((gamepad != null) && gamepad.anyInput())
			{
				IDsArray.push(gamepad.id);
			}
		}
		
		return IDsArray;
	}
	
	/**
	 * Get array of gamepads with any pressed buttons or moved Axis, Ball and Hat.
	 * 
	 * @param	GamepadArray	optional array to fill with active gamepads
	 * @return	array filled with active gamepads
	 */
	public function getActiveGamepads(?GamepadArray:Array<FlxGamepad>):Array<FlxGamepad>
	{
		if (GamepadArray == null)
		{
			GamepadArray = [];
		}
		
		for (gamepad in _gamepads)
		{
			if ((gamepad != null) && gamepad.anyInput())
			{
				GamepadArray.push(gamepad);
			}
		}
		
		return GamepadArray;
	}
	
	/**
	 * Get first found active gamepad id (with any pressed buttons or moved Axis, Ball and Hat).
	 * Returns "-1" if no active gamepad has been found.
	 */
	public function getFirstActiveGamepadID():Int
	{
		var firstActive:FlxGamepad = getFirstActiveGamepad();
		return (firstActive == null) ? -1 : firstActive.id;
	}
	
	/**
	 * Get first found active gamepad (with any pressed buttons or moved Axis, Ball and Hat).
	 * Returns null if no active gamepad has been found.
	 */
	public function getFirstActiveGamepad():FlxGamepad
	{
		for (gamepad in _gamepads)
		{
			if (gamepad != null && gamepad.anyInput())
			{
				return gamepad;
			}
		}
		
		return null;
	}
	
	/**
	 * Whether any buttons have the specified input state on any gamepad.
	 */
	public function anyButton(state:FlxInputState = PRESSED):Bool
	{
		for (gamepad in _gamepads)
		{
			if (gamepad != null && gamepad.anyButton(state))
			{
				return true;
			}
		}
		
		return false;
	}
	
	/**
	 * Check to see if any buttons are pressed right or Axis, Ball and Hat Moved on any gamepad.
	 */
	public function anyInput():Bool
	{
		for (gamepad in _gamepads)
		{
			if (gamepad != null && gamepad.anyInput())
			{
				return true;
			}
		}
		
		return false;
	}

	/**
	 * Check to see if this button is pressed on any Gamepad.
	 * 
	 * @param 	ButtonID  The button id (from 0 to 7).
	 * @return 	Whether the button is pressed
	 */
	public function anyPressed(buttonID:FlxGamepadID):Bool
	{
		for (gamepad in _gamepads)
		{
			if ((gamepad != null) && gamepad.checkStatus(buttonID,PRESSED))
			{
				return true;
			}
		}
		
		return false;
	}

	/**
	 * Check to see if this button was just pressed on any Gamepad.
	 * 
	 * @param 	ButtonID 	The button id (from 0 to 7).
	 * @return 	Whether the button was just pressed
	*/
	public function anyJustPressed(buttonID:FlxGamepadID):Bool
	{
		for (gamepad in _gamepads)
		{
			if ((gamepad != null) && gamepad.checkStatus(buttonID,JUST_PRESSED))
			{
				return true;
			}
		}
		
		return false;
	}

	/**
	 * Check to see if this button is just released on any Gamepad.
	 * 
	 * @param 	ButtonID 	The Button id (from 0 to 7).
	 * @return 	Whether the button is just released.
	*/
	public function anyJustReleased(buttonID:FlxGamepadID):Bool
	{
		for (gamepad in _gamepads)
		{
			if ((gamepad != null) && gamepad.checkStatus(buttonID,JUST_RELEASED))
			{
				return true;
			}
		}
		
		return false;
	}
	
	/**
	 * Check to see if the X axis is moved on any Gamepad.
	 * 
	 * @param AxisID The axis id
	 * @return Float Value from -1 to 1 or 0 if no X axes were moved
	 */
	public function anyMovedXAxis(RawAxisID:FlxGamepadAnalogStick):Float
	{
		for (gamepad in _gamepads)
		{
			if ((gamepad != null))
			{
				var value = gamepad.getXAxisRaw(RawAxisID);
				if (value != 0) return value;
			}
		}
		
		return 0;
	}

	/**
	 * Check to see if the Y axis is moved on any Gamepad.
	 * 
	 * @param AxisID The axis id
	 * @return Float Value from -1 to 1 or 0 if no Y axes were moved
	 */
	public function anyMovedYAxis(RawAxisID:FlxGamepadAnalogStick):Float
	{
		for (gamepad in _gamepads)
		{
			if ((gamepad != null))
			{
				var value = gamepad.getYAxisRaw(RawAxisID);
				if (value != 0) return value;
			}
		}
		
		return 0;
	}
	
	/**
	 * Clean up memory. Internal use only.
	 */
	@:noCompletion
	public function destroy():Void
	{
		for (gamepad in _gamepads)
		{
			gamepad = FlxDestroyUtil.destroy(gamepad);
		}
		
		firstActive = null;
		lastActive = null;
		_gamepads = null;
		
		#if (flash11_8 || next)
		// not sure this is needed - can't imagine any use case where FlxGamepadManager would be destroyed
		_gameInput.removeEventListener(GameInputEvent.DEVICE_ADDED, onDeviceAdded);
		_gameInput.removeEventListener(GameInputEvent.DEVICE_REMOVED, onDeviceRemoved);
		#end
	}
	
	/**
	 * Resets all the keys on all joys.
	 */
	public function reset():Void
	{
		for (gamepad in _gamepads)
		{
			if (gamepad != null)
			{
				gamepad.reset();
			}
		}
	}
	
	@:allow(flixel.FlxG)
	private function new() 
	{
		#if FLX_OPENFL_JOYSTICK_API
		FlxG.stage.addEventListener(JoystickEvent.AXIS_MOVE, handleAxisMove);
		FlxG.stage.addEventListener(JoystickEvent.BALL_MOVE, handleBallMove);
		FlxG.stage.addEventListener(JoystickEvent.BUTTON_DOWN, handleButtonDown);
		FlxG.stage.addEventListener(JoystickEvent.BUTTON_UP, handleButtonUp);
		FlxG.stage.addEventListener(JoystickEvent.HAT_MOVE, handleHatMove);
		FlxG.stage.addEventListener(JoystickEvent.DEVICE_REMOVED, handleDeviceRemoved);
		FlxG.stage.addEventListener(JoystickEvent.DEVICE_ADDED, handleDeviceAdded);
		#end
		
		#if (flash11_8 || next)
		_gameInput.addEventListener(GameInputEvent.DEVICE_ADDED, onDeviceAdded);
		_gameInput.addEventListener(GameInputEvent.DEVICE_REMOVED, onDeviceRemoved);
		
		for (i in 0...GameInput.numDevices)
		{
			addGamepad(GameInput.getDeviceAt(i));
		}
		#end
	}
	
	#if (flash11_8 || next)
	private function onDeviceAdded(Event:GameInputEvent):Void
	{
		addGamepad(Event.device);
	}
	
	private function onDeviceRemoved(Event:GameInputEvent):Void
	{
		removeGamepad(Event.device);
	}
	
	private function findGamepadIndex(Device:GameInputDevice):Int
	{
		if (Device != null)
		{
			for (i in 0...GameInput.numDevices)
			{
				var currentDevice = GameInput.getDeviceAt(i);
				if (currentDevice == Device)
				{
					return i;
				}
			}
		}
		return -1;
	}
	
	private function addGamepad(Device:GameInputDevice):Void
	{
		if (Device != null)
		{
			Device.enabled = true;
			var id:Int = findGamepadIndex(Device);
			
			if (id >= 0)
			{
				var gamepad:FlxGamepad = createByID(id, getModelFromFlashDeviceName(Device.name));
				gamepad._device = Device;
			}
		}
	}
	
	private function getModelFromFlashDeviceName(str:String):GamepadModel
	{
		str = str.toLowerCase();
		var strip = ["-", "_"];
		for (s in strip)
		{
			while (str.indexOf(s) != -1)
			{
				str = StringTools.replace(str, s, "");
			}
		}
		
		if (str.indexOf("xbox") != -1 && 
		    str.indexOf("360") != -1) return XBox360;             //"Microsoft X-Box 360 pad"
		if (str.indexOf("playstation") != -1) return PS3;         //"Sony PLAYSTATION(R)3 Controller"
		if (str.indexOf("ouya") != -1) return OUYA;               //"OUYA Game Controller"
		if (str.indexOf("wireless controller") != -1) return PS4; //"Wireless Controller"
		if (str.indexOf("logitech") != -1) return Logitech;
		if (str.indexOf("xinput") != -1) return XInput;
		
		return XBox360;	//default
	}
	
	private function removeGamepad(Device:GameInputDevice):Void
	{
		if (Device != null)
		{
			for (i in 0..._gamepads.length)
			{
				var gamepad:FlxGamepad = _gamepads[i];
				if (gamepad != null && gamepad._device == Device)
				{
					removeByID(i);
				}
			}
		}
	}
	#end
	
	#if FLX_OPENFL_JOYSTICK_API
	private function handleButtonDown(FlashEvent:JoystickEvent):Void
	{
		var gamepad:FlxGamepad = createByID(FlashEvent.device);
		var button:FlxGamepadButton = gamepad.getButton(FlashEvent.id);
		
		if (button != null) 
		{
			button.press();
		}
	}
	
	private function handleButtonUp(FlashEvent:JoystickEvent):Void
	{
		var gamepad:FlxGamepad = createByID(FlashEvent.device);
		var button:FlxGamepadButton = gamepad.getButton(FlashEvent.id);
		
		if (button != null) 
		{
			button.release();
		}
	}
	
	private function handleAxisMove(FlashEvent:JoystickEvent):Void
	{
		var gamepad:FlxGamepad = createByID(FlashEvent.device);
		gamepad.axis = FlashEvent.axis;
	}
	
	private function handleBallMove(FlashEvent:JoystickEvent):Void
	{
		var gamepad:FlxGamepad = createByID(FlashEvent.device);
		gamepad.ball.x = (Math.abs(FlashEvent.x) < gamepad.deadZone) ? 0 : FlashEvent.x;
		gamepad.ball.y = (Math.abs(FlashEvent.y) < gamepad.deadZone) ? 0 : FlashEvent.y;
	}
	
	private function handleHatMove(FlashEvent:JoystickEvent):Void
	{
		var gamepad:FlxGamepad = createByID(FlashEvent.device);
		
		var oldx = gamepad.hat.x;
		var oldy = gamepad.hat.y;
		
		var newx = (Math.abs(FlashEvent.x) < gamepad.deadZone) ? 0 : FlashEvent.x;
		var newy = (Math.abs(FlashEvent.y) < gamepad.deadZone) ? 0 : FlashEvent.y;
		
		gamepad.hat.x = newx;
		gamepad.hat.y = newy;
		
		#if !flash
			var newType:String = "";
			var newId:Int = 0;
			
			var change = false;
			
			//We see if there's been a change so we can properly set "justPressed"/"justReleased", etc.
			if (oldx != newx)
			{
				change = true;
				
				if (oldx == -1)
				{
					newType = JOYSTICK_BUTTON_UP;
					newId = gamepad.getRawID(FlxGamepadID.DPAD_LEFT);
				}
				else if (oldx == 1)
				{
					newType = JOYSTICK_BUTTON_UP;
					newId = gamepad.getRawID(FlxGamepadID.DPAD_RIGHT);
				}
				
				if (newx == -1)
				{
					newType = JOYSTICK_BUTTON_DOWN;
					newId = gamepad.getRawID(FlxGamepadID.DPAD_LEFT);
				}
				else if (newx == 1)
				{
					newType = JOYSTICK_BUTTON_DOWN;
					newId = gamepad.getRawID(FlxGamepadID.DPAD_RIGHT);
				}
			}
			
			if (oldy != newy)
			{
				change = true;
				
				if (oldy == -1)
				{
					newType = JOYSTICK_BUTTON_UP;
					newId = gamepad.getRawID(FlxGamepadID.DPAD_UP);
				}
				else if (oldy == 1)
				{
					newType = JOYSTICK_BUTTON_UP;
					newId = gamepad.getRawID(FlxGamepadID.DPAD_DOWN);
				}
				
				if (newy == -1)
				{
					newType = JOYSTICK_BUTTON_DOWN;
					newId = gamepad.getRawID(FlxGamepadID.DPAD_UP);
				}
				else if (newy == 1)
				{
					newType = JOYSTICK_BUTTON_DOWN;
					newId = gamepad.getRawID(FlxGamepadID.DPAD_DOWN);
				}
			}
			
			//Send a fake joystick button event that corresponds to the DPAD codes
			if (change && newType != "")
			{
				var newEvent = new JoystickEvent(newType, FlashEvent.bubbles, FlashEvent.cancelable, FlashEvent.device, newId, FlashEvent.x, FlashEvent.y, FlashEvent.z);
				
				if (newType == JOYSTICK_BUTTON_UP)
				{
					handleButtonUp(newEvent);
				}
				else if (newType == JOYSTICK_BUTTON_DOWN)
				{
					handleButtonDown(newEvent);
				}
			}
		#end
	}

	private function handleDeviceAdded(event:JoystickEvent):Void
	{
		createByID(event.device);
	}
	
	private function handleDeviceRemoved(event:JoystickEvent):Void
	{
		removeByID(event.device);
	}
	#end
	
	/**
	 * Updates the key states (for tracking just pressed, just released, etc).
	 */
	private function update():Void
	{
		for (gamepad in _gamepads)
		{
			if (gamepad != null)
			{
				gamepad.update();
			}
		}
	}
	
	private inline function onFocus():Void {}

	private inline function onFocusLost():Void
	{
		reset();
	}

	private function get_numActiveGamepads():Int
	{
		var count = 0;
		for (gamepad in _gamepads)
		{
			if (gamepad != null)
			{
				count++;
			}
		}
		return count;
	}
	
	/**
	 * Facility function to set the deadzone on every available gamepad.
	 * @param	DeadZone	Joystick deadzone. Sets the sensibility. 
	 * 						Less this number the more Joystick is sensible.
	 * 						Should be between 0.0 and 1.0.
	 */
	private function set_globalDeadZone(DeadZone:Float):Float
	{
		globalDeadZone = DeadZone;
		for (gamepad in _gamepads)
		{
			if (gamepad != null)
			{
				gamepad.deadZone = DeadZone;
			}
		}
		return globalDeadZone;
	}
	
	#if (!flash)
	
	private static inline var JOYSTICK_BUTTON_UP:String = "buttonUp";
	private static inline var JOYSTICK_BUTTON_DOWN:String = "buttonDown";
	
	#end
}