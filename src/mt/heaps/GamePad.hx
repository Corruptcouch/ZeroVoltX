package mt.heaps;

@:enum
abstract PadKey(Int) {
	var A               = 0;
	var B               = 1;
	var X               = 2;
	var Y               = 3;
	var SELECT          = 4;
	var START           = 5;
	var LT              = 6;
	var RT              = 7;
	var LB              = 8;
	var RB              = 9;
	var LSTICK          = 10;
	var RSTICK          = 11;
	var DPAD_UP         = 12;
	var DPAD_DOWN       = 13;
	var DPAD_LEFT       = 14;
	var DPAD_RIGHT      = 15;
	var AXIS_LEFT_X     = 16;
	var AXIS_LEFT_X_NEG = 17;
	var AXIS_LEFT_X_POS = 18;
	var AXIS_LEFT_Y     = 19;
	var AXIS_LEFT_Y_NEG = 20;
	var AXIS_LEFT_Y_POS = 21;
	var AXIS_RIGHT_X    = 22;
	var AXIS_RIGHT_Y    = 23;

	public inline function new( v : Int ){
		this = v;
	}

	public inline function getIndex() : Int {
		return this;
	}

	inline public static var LENGTH = 24;
}

class GamePad {
	public static var ALL : Array<GamePad> = [];
	public static var AVAILABLE_DEVICES : Array<hxd.Pad>;

	static var MAPPINGS : Array<{?generic: Bool, ?ids: Array<String>, map: Map<PadKey,Int>}> = [
		#if flash
		{
			ids : ["xbox","x-box"],
			map : [
				AXIS_LEFT_X => 0,
				AXIS_LEFT_X_NEG => 0,
				AXIS_LEFT_X_POS => 0,
				AXIS_LEFT_Y => 1,
				AXIS_LEFT_Y_NEG => 1,
				AXIS_LEFT_Y_POS => 1,
				AXIS_RIGHT_X => 2,
				AXIS_RIGHT_Y => 3,
				A => 4,
				B => 5,
				X => 6,
				Y => 7,
				LB => 8,
				RB => 9,
				LT => 10,
				RT => 11,
				SELECT => 12,
				START => 13,
				LSTICK => 14,
				RSTICK => 15,
				DPAD_UP => 16,
				DPAD_DOWN => 17,
				DPAD_LEFT => 18,
				DPAD_RIGHT => 19,
			],
		},
		#elseif hlsdl
		{
			generic: true,
			map : [
				AXIS_LEFT_X => 0,
				AXIS_LEFT_X_NEG => 0,
				AXIS_LEFT_X_POS => 0,
				AXIS_LEFT_Y => 1,
				AXIS_LEFT_Y_NEG => 1,
				AXIS_LEFT_Y_POS => 1,
				AXIS_RIGHT_X => 2,
				AXIS_RIGHT_Y => 3,
				A => 6,
				B => 7,
				X => 8,
				Y => 9,
				LB => 15,
				RB => 16,
				LT => 4,
				RT => 5,
				SELECT => 10,
				START => 12,
				LSTICK => 13,
				RSTICK => 14,
				DPAD_UP => 17,
				DPAD_DOWN => 18,
				DPAD_LEFT => 19,
				DPAD_RIGHT => 20,
			],
		},
		#elseif hldx
		{
			generic: true,
			map : [
				AXIS_LEFT_X => 14,
				AXIS_LEFT_X_NEG => 14,
				AXIS_LEFT_X_POS => 14,
				AXIS_LEFT_Y => 15,
				AXIS_LEFT_Y_NEG => 15,
				AXIS_LEFT_Y_POS => 15,
				AXIS_RIGHT_X => 16,
				AXIS_RIGHT_Y => 17,
				A => 10,
				B => 11,
				X => 12,
				Y => 13,
				LB => 8,
				RB => 9,
				LT => 18,
				RT => 19,
				SELECT => 5,
				START => 4,
				LSTICK => 6,
				RSTICK => 7,
				DPAD_UP => 0,
				DPAD_DOWN => 1,
				DPAD_LEFT => 2,
				DPAD_RIGHT => 3,
			],
		},
		#end
	];

	var device				: Null<hxd.Pad>;
	var toggles				: Array<Int>;
	var mapping				: haxe.ds.Vector<Int>;

	//var inverts				: Map<String,Bool>;
	public var deadZone		: Float = 0.18;
	public var lastActivity(default,null) : Float;

	public function new(?deadZone:Float, ?onEnable:GamePad->Void) {
		ALL.push(this);
		toggles = [];
		mapping = new haxe.ds.Vector( PadKey.LENGTH );
		for( i in 0...mapping.length ) mapping[i] = -1;

		if( deadZone!=null )
			this.deadZone = deadZone;

		if( onEnable!=null )
			this.onEnable = onEnable;

		if( AVAILABLE_DEVICES==null ){
			AVAILABLE_DEVICES = [];
			hxd.Pad.wait( onDevice );
		}

		lastActivity = haxe.Timer.stamp();
	}

	public dynamic function onEnable(pad:GamePad) {}
	public dynamic function onDisable(pad:GamePad) {}
	public inline function isEnabled() return device!=null;

	public inline function toString() return "GamePad("+getDeviceId()+")";
	public inline function getDeviceName() : Null<String> return device==null ? null : device.name;
	public inline function getDeviceId() : Null<Int> return device==null ? null : device.index;

	function enableDevice( p : hxd.Pad ) {
		if( device==null ) {
			AVAILABLE_DEVICES.remove( p );
			p.onDisconnect = function(){
				disable();
			}
			for( i in 0...mapping.length ) mapping[i] = -1;
			var pname = p.name.toLowerCase();
			for( m in MAPPINGS ){
				var isValid = m.generic;
				if( m.ids != null ){
					for( id in m.ids ){
						if( pname.indexOf(id) > -1 ){
							isValid = true;
							break;
						}
					}
				}
				if( isValid ){
					for( k in m.map.keys() )
						mapping[ k.getIndex() ] = m.map[k];
				}
			}
			device = p;
			onEnable( this );
		}
	}

	function disable() {
		if( device!=null ) {
			device = null;
			onDisable(this);
		}
	}

	function onDevice( p : hxd.Pad ) {
		for( i in ALL ){
			if( i.device == null ){
				i.enableDevice( p );
				return;
			}
		}

		AVAILABLE_DEVICES.push( p );
		p.onDisconnect = function() AVAILABLE_DEVICES.remove( p );
	}

	public function dispose() {
		ALL.remove(this);
		if( device != null )
			onDevice( device );
		device = null;
	}

	public function rumble( strength : Float, length : Int ) {
		if( isEnabled() )
			device.rumble(strength, length);
	}

	inline function getControlValue(idx:Int, simplified:Bool, ?overrideDeadZone:Float) : Float {
		var v = idx > -1 && idx<device.values.length ? device.values[idx] : 0;
		//if( inverts.get(cid)==true )
		//	v*=-1;

		var dz = overrideDeadZone!=null ? overrideDeadZone : deadZone;

		if( simplified )
			return v<-dz?-1 : (v>dz?1 : 0);
		else
			return v>-dz && v<dz ? 0 : v;
	}

	public inline function getValue(k:PadKey, simplified=false, ?overrideDeadZone:Float) : Float {
		return isEnabled() ? getControlValue( mapping[k.getIndex()], simplified, overrideDeadZone ) : 0.;
	}

	public inline function isDown(k:PadKey) {
		switch( k ) {
			case AXIS_LEFT_X_NEG, AXIS_LEFT_Y_NEG : return getValue(k,true)<0;
			case AXIS_LEFT_X_POS, AXIS_LEFT_Y_POS : return getValue(k,true)>0;
			default : return getValue(k,true)!=0;
		}
	}

	public /*inline */function isPressed(k:PadKey) {
		var idx = mapping[k.getIndex()];
		var t = isEnabled() && idx>-1 && idx<device.values.length ? toggles[idx] : 0;
		return (t==1 || t==2) && isDown(k);
	}

	public static function update() {
		for(e in ALL){
			var hasToggle = false;
			if( e.device!=null ){
				for(i in 0...e.device.values.length) {
					if( MLib.fabs( e.device.values[i] ) > e.deadZone ){
						hasToggle = true;
						if ( e.toggles[i] >= 2 )
							e.toggles[i] = 3;
						else
							e.toggles[i] = 2;
					}else{
						e.toggles[i] = 0;
					}
				}
			}
			if( hasToggle )
				e.lastActivity = haxe.Timer.stamp();
		}
	}
}
