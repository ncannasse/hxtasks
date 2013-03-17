package db;
import sys.db.Types;

class Share extends sys.db.Object {

	public var id : SId;
	@:relation(gid)
	public var group : Group;
	@:relation(tid)
	public var task : Task;
	
}