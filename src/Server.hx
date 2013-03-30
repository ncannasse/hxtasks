import Common;

typedef Config = {
	var db : Dynamic;
	var salt : String;
}

class Server {

	var user : db.User;
	
	function new(auth: { name:String, pass:String } ) {
		try {
			user = db.User.manager.select($name == auth.name && $pass == db.User.encodePass(auth));
		} catch( e : Dynamic ) {
			// check if database exists
			var hasDB = try { sys.db.Manager.cnx.request("DESC User"); true; } catch( e : Dynamic ) false;
			if( hasDB ) neko.Lib.rethrow(e);
			spadm.Admin.initializeDatabase(true, true);
			throw "Database initialized";
		}
		// first user logged = create as admin
		if( db.User.manager.count(true) == 0 ) {
			user = new db.User();
			user.name = auth.name;
			user.pass = db.User.encodePass(auth);
			user.isAdmin = true;
			user.insert();
			var g = new db.Group();
			g.name = user.name;
			g.insert();
			var gu = new db.GroupUser();
			gu.user = user;
			gu.group = g;
			gu.insert();
			var t = new db.Task();
			t.text = "Default";
			t.isGroup = true;
			t.insert();
			t.order = t.id;
			t.update();
			var s = new db.Share();
			s.group = g;
			s.task = t;
			s.owner = user;
			s.insert();
		}
	}
	
	function exec() {
		if( user == null ) {
			requireHttpAuth();
			return;
		}
		try {
			var uri = neko.Web.getURI();
			if( StringTools.endsWith(uri, "index.n") )
				uri = uri.substr(0, uri.length - 7);
			new haxe.web.Dispatch(uri, neko.Web.getParams()).dispatch(this);
		} catch( e : haxe.web.Dispatch.DispatchError ) {
			if( user.isAdmin )
				neko.Lib.rethrow(e+" for "+neko.Web.getURI());
			neko.Web.redirect("/");
		}
	}
	
	function doDefault() {
		Sys.print(sys.io.File.getContent(DIR + "www/home.html"));
	}
	
	function doDb( d : haxe.web.Dispatch ) {
		if( !user.isAdmin ) {
			neko.Web.redirect("/");
			return;
		}
		spadm.Admin.handler();
	}
	
	function doAct( action : String ) {
		try {
			var a = haxe.Unserializer.run(action);
			var ret = handle(a);
			Sys.print(haxe.Serializer.run(ret));
		} catch( e : Dynamic ) {
			var stack = haxe.CallStack.toString(haxe.CallStack.exceptionStack());
			var str = Std.string(e);
			if( user.isAdmin ) str += "\n" + stack;
			var s = new haxe.Serializer();
			s.serializeException(str);
			Sys.print(s.toString());
		}
	}
	
	function handle<T>( act : Action<T> ) : T {
		var l = new db.Log();
		l.user = user;
		l.date = Date.now();
		if( act.getIndex() != Load.getIndex() )
			l.action = db.Log.LogAction.createByIndex(act.getIndex() - 1);
		switch( act ) {
		case Load:
			var shares = [];
			for( g in db.GroupUser.manager.search($user == user,false) )
				for( s in db.Share.manager.search($group == g.group,false) )
					shares.push(s);
			var roots = new Array<Task>();
			function addRec( t : db.Task ) : Task {
				var tsubs = null;
				if( t.isGroup ) {
					tsubs = [];
					for( t in db.Task.manager.search($parent == t && !$done,{orderBy:order},false) )
						tsubs.push(addRec(t));
				}
				return {
					id : t.id,
					text : t.text,
					priority : t.priority,
					subs : tsubs,
					done : t.done,
				};
			}
			for( t in shares )
				roots.push(addRec(t.task));
			var t : Task = {
				id : 0,
				text : "(root)",
				priority : 0,
				subs : roots,
				done : false,
			};
			return cast t;
		case Create(text, pid):
			var t = if( pid == 0 ) null else getTask(pid);
			var ts = new db.Task();
			ts.parent = t;
			ts.text = text;
			ts.insert();
			ts.order = ts.id;
			ts.update();
			l.task = t;
			l.newInt = pid;
			l.newString = text;
			if( pid == 0 ) {
				// look for a group with only our user
				var group = null;
				for( g in db.GroupUser.manager.search($user == user, false) )
					if( db.GroupUser.manager.count($group == g.group) == 1 ) {
						group = g.group;
						break;
					}
				// or create it
				if( group == null ) {
					group = new db.Group();
					group.name = user.name;
					group.insert();
					var gu = new db.GroupUser();
					gu.group = group;
					gu.user = user;
					gu.insert();
				}
				var s = new db.Share();
				s.group = group;
				s.task = ts;
				s.owner = user;
				s.insert();
				l.newInt = -s.id;
				ts.isGroup = true;
				ts.update();
			}
			l.insert();
			return cast ts.id;
		case Rename(id, old, newText):
			var t = getTask(id);
			if( t.text != old )
				return cast false;
			t.text = newText;
			t.update();
			l.task = t;
			l.oldString = old;
			l.newString = newText;
			l.insert();
			return cast true;
		case Mark(id, m):
			var t = getTask(id);
			if( t.done == m )
				return cast false;
			t.done = m;
			t.update();
			l.task = t;
			l.newInt = t.done ? 1 : 0;
			l.insert();
			return cast true;
		case SetPriority(id, p):
			var t = getTask(id);
			if( t.priority == p )
				return cast true;
			l.task = t;
			l.oldInt = t.priority;
			l.newInt = p;
			l.insert();
			t.priority = p;
			t.update();
			return cast true;
		case Delete(id):
			var t = getTask(id);
			if( t.parent == null ) {
				var share = null;
				for( s in db.Share.manager.search($tid == t.id) )
					if( s.owner == user ) {
						share = s;
						break;
					}
				if( share == null )
					throw "You cannot unshare a task you don't own";
				share.delete();

				l.task = t;
				l.oldInt = -share.group.id; // unshare
				l.insert();
				
			} else {
				l.task = t;
				l.oldInt = t.parent.id;
				l.insert();
				
				t.parent = null;
				t.update();
			}
			return cast true;
		case MakeGroup(id):
			var t = getTask(id);
			if( t.isGroup )
				return cast false;
			t.isGroup = true;
			t.update();
			l.task = t;
			l.insert();
			return cast true;
		case MoveTo(id, oldP, newP):
			var t = getTask(id);
			if( t.parent == null || t.parent.id != oldP )
				return cast false;
			l.task = t;
			l.oldInt = oldP;
			l.newInt = newP;
			l.insert();
			
			t.parent = getTask(newP);
			t.update();
			return cast true;
		case Order(id, target):
			var t = getTask(id);
			var target = getTask(target);
			var childs;
			
			l.task = t;
			l.oldInt = t.order;

			
			if( target == t.parent ) {
				childs = Lambda.array(db.Task.manager.search($parent == target));
				childs.remove(t);
				childs.unshift(t);
			} else {
				if( target.parent != t.parent )
					return cast false;
				childs = Lambda.array(db.Task.manager.search($parent == target.parent));
				childs.remove(t);
				childs.insert(Lambda.indexOf(childs,target) + 1, t);
			}
			for( i in 0...childs.length ) {
				var a = childs[i];
				for( j in i + 1...childs.length ) {
					var b = childs[j];
					if( a.order > b.order ) {
						var tmp = b.order;
						b.order = a.order;
						a.order = tmp;
					}
				}
			}
			for( c in childs )
				c.update();
			
			l.newInt = t.order;
			l.insert();
			
			return cast true;
		}
	}
	
	function getTask(id) {
		var t = db.Task.manager.get(id);
		if( t == null || !t.canAccess(user) )
			throw "assert";
		return t;
	}
		
	static var DIR = neko.Web.getCwd() + "../";
	public static var CFG : Config = haxe.Json.parse(sys.io.File.getContent(DIR + "config.js"));
	
	static function requireHttpAuth(){
		neko.Web.setReturnCode( 401 );
		neko.Web.setHeader("status","401 Authorization Required");
		neko.Web.setHeader("WWW-Authenticate","Basic realm=\"Please identify yourself\"");
	}

	static function main() {
		var auth = neko.Web.getAuthorization();
		if( auth == null ) {
			requireHttpAuth();
			return;
		}
		var cnx = sys.db.Mysql.connect(CFG.db);
		sys.db.Transaction.main(cnx, function() new Server({name:auth.user,pass:auth.pass}).exec());
	}
	
}