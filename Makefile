ROPTIONS=-zav --delete --exclude=.svn --chmod=ug=rwX,o= --exclude=www/file --exclude=.htaccess

all:
	haxe hxtasks.hxml
	
deploy:
	rsync $(ROPTIONS) www upload@shiro.fr:/data/hxtasks