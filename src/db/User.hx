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
	
	@:skip
	var sharesCache : Map<Int,Bool>;
	
	public function getShares() {
		if( sharesCache == null )
			sharesCache = new Map();
		for( g in GroupUser.manager.search($user == this, false) )
			for( s in Share.manager.search($group == g.group, false) )
				sharesCache.set(s.task.id, false);
		return sharesCache;
	}
	
	public static function encodePass(o) {
		return haxe.crypto.Md5.encode(haxe.crypto.Sha1.encode(o.pass) + Server.CFG.salt);
	}
	
}