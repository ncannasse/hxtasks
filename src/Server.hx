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
			g.name = "Default";
			g.insert();
			var gu = new db.GroupUser();
			gu.user = user;
			gu.group = g;
			gu.insert();
			var t = new db.Task();
			t.text = "Default";
			t.isGroup = true;
			t.insert();
			var s = new db.Share();
			s.group = g;
			s.task = t;
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
	
	function doLoad() {
		var shares = [];
		for( g in db.GroupUser.manager.search($user == user) )
			for( s in db.Share.manager.search($group == g.group) )
				shares.push(s);
		var roots = new Array<Common.Task>();
		function addRec( t : db.Task ) : Common.Task {
			var tsubs = null;
			if( t.isGroup ) {
				tsubs = [];
				for( t in db.Task.manager.search($parent == t) )
					tsubs.push(addRec(t));
			}
			return {
				id : t.id,
				text : t.text,
				priority : t.priority,
				subs : tsubs,
			};
		}
		for( t in shares )
			roots.push(addRec(t.task));
		var t : Common.Task = {
			id : 0,
			text : "(root)",
			priority : 0,
			subs : roots,
		};
		ret(t);
	}
	
	function ret( v : Dynamic ) {
		Sys.print(haxe.Serializer.run(v));
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