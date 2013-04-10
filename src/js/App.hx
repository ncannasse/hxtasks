package js;

import Common;

class App {

	static var UID = 0;
	
	var root : Task;
	var opened : Map<Int,Bool>;
	var parents : Map<Int,Task>;
	var alls : Map<Int,Task>;
	var menu : JQuery;
	var lock : JQuery;
	var curDrag : Task;
	var curDragTarget : Task;
	var history : Array<Action<Dynamic>>;
	
	public function new() {
		try {
			opened = haxe.Unserializer.run(Browser.window.localStorage.getItem("tasks_open"));
		} catch( e : Dynamic ) {
			opened = new Map();
		}
		opened.set(0, true);
		menu = J("#tmenu");
		lock = J("#lock");
		lock.remove();
		resync();
	}
	
	function init() {
		J("#search").append(J("<input>").addClass("search-query").attr("placeholder", "Search").keyup(function(_) filter(JQuery.cur.val())));
	}
	
	function getText(id, ?p: { } ) {
		var t = J("#" + id).html();
		if( t == null || t == "" ) t = "#" + id;
		if( p != null )
			for( f in Reflect.fields(p) )
				t = t.split("$" + f).join(Reflect.field(p, f));
		return t;
	}
	
	function saveView() {
		Browser.window.localStorage.setItem("tasks_open", haxe.Serializer.run(opened));
	}
	
	function load<T>( act : Action<T>, onData : T -> Void ) {
		switch( act ) {
		case Load:
			history = [];
		default:
			history.push(act);
		}
		J("#loading").removeClass("off");
		var h = new haxe.Http("/act/"+StringTools.urlEncode(haxe.Serializer.run(act)));
		h.onError = function(msg) {
			J("#loading").addClass("off");
			Lib.alert(msg);
		};
		h.onData = function(data) {
			J("#loading").addClass("off");
			var val = null;
			try {
				val = haxe.Unserializer.run(data);
			} catch( e : String ) {
				h.onError(e);
				switch( act ) {
				case Load:
				default: resync();
				}
			} catch( e : Dynamic ) {
				h.onError(e + " in " + data);
				return;
			}
			try onData(val) catch( e : Dynamic ) h.onError(e);
		};
		h.request(true);
	}
	
	function display() {
		alls = new Map();
		parents = new Map();
		alls.set(0, root);
		var b = buildChilds(root.subs, root);
		J("#tasks").html("").append(b);
	}
	
	function buildChilds( tl : Array<Task>, parent ) : JQuery {
		var ul = J("<ul>").addClass("l");
		for( t in tl ) {
			parents.set(t.id, parent);
			ul.append(buildTask(t,parent));
		}
		return ul;
	}
	
	function taskOf( j : JQuery ) {
		var id = Std.parseInt(j.attr("id").substr(2));
		return alls.get(id);
	}
	
	function buildTask( t : Task, ?parent : Task ) : JQuery {
		var ico = J("<div>").addClass("i");
		var desc = J("<div>").addClass("desc").text(t.text);
		var content = J("<div>").append(ico).append(desc);
		var div = J("<div>").addClass("t").attr("id", "_t" + t.id).addClass("p" + t.priority).append(content);
		var li = J("<li>").addClass("t").append(div);
		alls.set(t.id, t);
		content.attr("draggable", "true");
		content.mouseover(function(_) div.addClass("over"));
		content.mouseout(function(_) div.removeClass("over"));
		content.on({
			dragstart : function(_) {
				li.addClass("drag");
				curDrag = t;
				curDragTarget = null;
			},
			dragend : function(_) {
				li.removeClass("drag");
				if( curDragTarget != null ) {
					parent.subs.remove(t);
					var moved = null;
					if( curDragTarget.subs == null ) {
						var np = parents.get(curDragTarget.id);
						moved = np;
						np.subs.insert(Lambda.indexOf(np.subs, curDragTarget) + 1, t);
					} else {
						moved = curDragTarget;
						curDragTarget.subs.unshift(t);
					}
					if( moved != parent )
						load(MoveTo(t.id, parent.id, moved.id), function(b) {
							if( !b ) resync() else load(Order(t.id, curDragTarget.id), resync);
						});
					else
						load(Order(t.id, curDragTarget.id), resync);
				}
				display();
			},
			dragenter : function(e:JQuery.JqEvent) {
				var cur = t;
				while( cur != null ) {
					if( cur == curDrag )
						return;
					cur = parents.get(cur.id);
				}
				var elt = get(curDrag).parent();
				if( t.subs == null )
					get(t).parent().after(elt);
				else {
					if( !opened.get(t.id) )
						toggleTask(t);
					li.children("ul").prepend(elt);
				}
				e.preventDefault();
				curDragTarget = t;
			},
		});
		if( t.subs != null ) {
			li.addClass("childs");
			if( !opened.get(t.id) )
				li.addClass("closed");
			li.append(buildChilds(t.subs,t));
			content.click(toggleTask.bind(t));
			ico.dblclick(function(_) addTask(t));
		} else {
			li.addClass("nochilds");
			desc.click(editTask.bind(t));
			ico.dblclick(function(_) toggleMark(t));
		}
		if( t.done )
			li.addClass("marked");
		content.bind("contextmenu", function(_) {
			showMenu(t);
			return false;
		});
		return li;
	}
	
	function showMenu( t : Task ) {
		var td = get(t);
		lock.click(function(_) {
			menu.hide();
			menu.find('a').unbind();
			lock.remove();
		});
		lock.bind("contextmenu", function(_) {
			lock.click();
			return false;
		});
		J("body").append(lock);
		function buildMenu(subs:Array<Task>) : JQuery {
			var ul = J("<ul>").addClass("dropdown-menu");
			var hasContent = false;
			for( t2 in subs ) {
				if( t == t2 || t2.subs == null ) continue;
				hasContent = true;
				var sub = buildMenu(t2.subs);
				var li = J("<li>").append(J("<a>").data("menu", "move").data("id", "" + t2.id).attr("href", "#").text(t2.text)).append(sub);
				if( sub != null ) li.addClass("dropdown-submenu");
				ul.append(li);
			}
			return hasContent ? ul : null;
		}
		td.append(menu);
		var move = menu.find("#moveTargets");
		move.children("ul").remove();
		move.append(buildMenu(root.subs));
		menu.find("a").click(function(e:JQuery.JqEvent) {
			menuAction(t, JQuery.cur.data("menu"), JQuery.cur.data("id"));
			e.stopPropagation();
		});
		if( t.subs == null ) menu.removeClass("isGroup") else menu.addClass("isGroup");
		menu.show(100);
	}
	
	function toggleTask( t : Task ) {
		var o = !opened.get(t.id);
		opened.set(t.id, o);
		saveView();
		var sub = get(t).parent().toggleClass("closed").children("ul.l");
		if( o ) {
			sub.hide();
			sub.show(100);
		} else
			sub.hide(100);
	}
	
	function toggleMark( t : Task ) {
		t.done = !t.done;
		get(t).parent().toggleClass("marked");
		load(Mark(t.id, t.done), resync);
	}
	
	function setPriority( t : Task, val : Int ) {
		t.priority = val;
		load(SetPriority(t.id, val), resync);
		display();
	}
	
	function deleteTask( t : Task, ?force ) {
		if( t.subs != null && t.subs.length > 0 && !force ) {
			if( !Browser.window.confirm(getText("confirm-delete", { name : t.text } )) )
				return;
		}
		parents.get(t.id).subs.remove(t);
		opened.remove(t.id);
		load(Delete(t.id), resync);
		display();
	}
	
	function moveTo( t : Task, to : Task ) {
		var oldp = parents.get(t.id);
		if( oldp == null ) return;
		oldp.subs.remove(t);
		to.subs.push(t);
		display();
		load(MoveTo(t.id, oldp.id, to.id), resync);
	}
	
	function resync( ?cancel = false ) {
		if( cancel ) return;
		load(Load, function(data) {
			if( root == null ) init();
			root = data;
			display();
		});
	}
	
	function editTask( t : Task ) {
		var td = get(t);
		if( td.hasClass("edit") )
			return;
		var tf = J("<input>");
		td.addClass("edit").append(tf);
		function onBlur(e) {
			var old = t.text;
			tf.remove();
			if( e != null )
				t.text = tf.val();
			td.find("div.desc").text(t.text);
			td.removeClass("edit");
			if( t.text == "" || (e == null && t.id < 0) ) {
				parents.get(t.id).subs.remove(t);
				display();
			} else if( old != t.text ) {
				if( t.id < 0 )
					load(Create(t.text, parents.get(t.id).id), function(id) { t.id = id; display(); });
				else
					load(Rename(t.id, old, t.text), resync);
			}
		}
		function onKey(k:JQuery.JqEvent) {
			switch( k.keyCode ) {
			case 27:
				onBlur(null);
			case 13:
				onBlur(k);
			default:
			}
		}
		tf.val(t.text);
		tf.blur(onBlur);
		tf.keydown(onKey);
		tf.focus();
	}

	function menuAction(cur:Task, act:String, param:Int) {
		if( act == null ) return;
		lock.click(); // hide menu
		switch( act ) {
		case "prio":
			setPriority(cur, param);
		case "add":
			addTask(cur);
		case "delete":
			deleteTask(cur);
		case "rename":
			editTask(cur);
		case "move":
			moveTo(cur, alls.get(param));
		case "mark":
			toggleMark(cur);
		case "mkgrp":
			if( cur.subs == null ) cur.subs = [];
			opened.set(cur.id, true);
			load(MakeGroup(cur.id), resync);
			display();
		default:
			Lib.alert("Unknown " + act);
		}
	}

	function get( t : Task ) {
		return J("#_t" + t.id);
	}

	function filter( value : String ) {
		if( value == "" ) {
			display();
			return;
		}
		var words = value.toLowerCase().split(" ");
		var forceOpen = [];
		function loop( t : Task ) {
			var txt = t.text.toLowerCase();
			var match = true;
			for( w in words )
				if( txt.indexOf(w) == -1 ) {
					match = false;
					break;
				}
			if( t.subs != null )
				for( t in t.subs )
					if( loop(t) )
						match = true;
			if( !match )
				get(t).parent().addClass("filtered");
			else if( t.subs != null && !opened.get(t.id) ) {
				opened.set(t.id, true);
				forceOpen.push(t.id);
			}
			return match;
		}
		J(".filtered").removeClass("filtered");
		loop(root);
		if( forceOpen.length > 0 ) {
			display();
			loop(root);
			for( f in forceOpen )
				opened.remove(f);
		}
	}

	function addTask( parent : Task ) {
		if( parent.subs == null )
			parent = parents.get(parent.id);
		var tnew = {
			id : -(++UID), // new task
			text : "",
			priority : 0,
			subs : null,
			done : false,
		};
		opened.set(parent.id, true);
		saveView();
		parent.subs.push(tnew);
		display();
		editTask(tnew);
	}
	
	function createNew() {
		var tnew = {
			id : -(++UID), // new task
			text : "",
			priority : 0,
			subs : [],
			done : false,
		};
		root.subs.push(tnew);
		display();
		editTask(tnew);
	}
	
	static function J(t:String) {
		return new JQuery(t);
	}
	
	static function main() {
		untyped Browser.window._ = new App();
	}
	
}