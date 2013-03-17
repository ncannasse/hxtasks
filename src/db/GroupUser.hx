package db;
import sys.db.Types;

@:id(gid,uid)
class GroupUser extends sys.db.Object {

	@:relation(gid)
	public var group : Group;
	@:relation(uid)
	public var user : User;
	
}