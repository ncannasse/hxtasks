package db;
import sys.db.Types;

class User extends sys.db.Object {

	public var id : SId;
	public var name : STinyText;
	public var pass : STinyText;
	public var isAdmin : Bool;
	
	override function insert() {
		if( pass.length != 32 )
			pass = encodePass(this);
		super.insert();
	}
	
	public static function encodePass(o) {
		return haxe.crypto.Md5.encode(haxe.crypto.Sha1.encode(o.pass) + Server.CFG.salt);
	}
	
}