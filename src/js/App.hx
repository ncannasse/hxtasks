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
	
	public function new() {
		opened = new Map();
		opened.set(0, true);
		menu = J("#tmenu");
		lock = J("#lock");
		lock.remove();
		load();
	}
	
	function load() {
		var id = 0;
		function make(t,?subs) : Task {
			return {
				id : id++,
				text : t,
				priority : 0,
				subs : subs,
			}
		}
		root = make("(root)",[
				make("test"),
				make("another", [
					make("sub1", [make("a"),make("b"),make("c")]),
					make("sub2", [make("x"),make("y"),make("s")]),
					make("sub3"),
				]),
			]);
		display();
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
	
	function buildTask( t : Task, ?parent : Task ) : JQuery {
		var ico = J("<div>").addClass("i");
		var desc = J("<div>").addClass("desc").text(t.text);
		var content = J("<div>").append(ico).append(desc);
		var div = J("<div>").addClass("t").attr("id", "_t" + t.id).addClass("p" + t.priority).append(content);
		var li = J("<li>").addClass("t").append(div);
		alls.set(t.id, t);
		content.mouseover(function(_) div.addClass("over"));
		content.mouseout(function(_) div.removeClass("over"));
		if( t.subs != null ) {
			li.addClass("childs");
			if( !opened.get(t.id) )
				li.addClass("closed");
			li.append(buildChilds(t.subs,t));
			content.click(toggleTask.bind(t));
		} else {
			li.addClass("nochilds");
			content.click(editTask.bind(t));
		}
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
		menu.show(100);
	}
	
	function toggleTask( t : Task ) {
		var o = !opened.get(t.id);
		opened.set(t.id, o);
		var sub = get(t).parent().toggleClass("closed").children("ul.l");
		if( o ) {
			sub.hide();
			sub.show(100);
		} else
			sub.hide(100);
	}
	
	function editTask( t : Task ) {
		var td = get(t);
		if( td.hasClass("edit") )
			return;
		var tf = J("<input>");
		td.addClass("edit").append(tf);
		function onBlur(e) {
			tf.remove();
			if( e != null )
				t.text = tf.val();
			td.find("div.desc").text(t.text);
			td.removeClass("edit");
			if( t.text == "" || (e == null && t.id < 0) ) {
				parents.get(t.id).subs.remove(t);
				display();
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
			cur.priority = param;
			display();
		case "add":
			if( cur.subs == null )
				cur = parents.get(cur.id);
			var tnew = {
				id : -(++UID), // new task
				text : "",
				priority : 0,
				subs : null,
			};
			opened.set(cur.id, true);
			cur.subs.push(tnew);
			display();
			editTask(tnew);
		case "delete":
			parents.get(cur.id).subs.remove(cur);
			opened.remove(cur.id);
			display();
		case "rename":
			editTask(cur);
		case "move":
			parents.get(cur.id).subs.remove(cur);
			alls.get(param).subs.push(cur);
			display();
		default:
			Lib.alert("Unknown " + act);
		}
	}

	function get( t : Task ) {
		return J("#_t" + t.id);
	}

	static function J(t:String) {
		return new JQuery(t);
	}
	
	static function main() {
		untyped Browser.window._ = new App();
	}
	
}