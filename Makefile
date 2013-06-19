HEADER = make/header.js
FOOTER = make/footer.js
LIBITEMS = lib/underscore.js lib/moment.js lib/raphael.js
EXAMPLes = compiled/examples
OBJS = polychart2.js polychart2.min.js polychart2.standalone.js tests.js examples.js

all: polychart2 polychart2.min polychart2.standalone examples tests clean-folders

dev: polychart2 examples

lib: polychart2 clean-folders

production: polychart2.standalone

polychart2:
	mkdir -p tmp
	mkdir -p compiled
	coffee --compile --output tmp/src/ src/
	cat\
		tmp/src/utils.js \
    tmp/src/const.js \
    tmp/src/error.js \
    tmp/src/abstract.js\
    tmp/src/mouse.js \
    tmp/src/format.js \
    tmp/src/type.js \
    tmp/src/spec.js \
    tmp/src/ajax.js \
    tmp/src/parser.js \
    tmp/src/coord.js \
    tmp/src/domain.js \
    tmp/src/tick.js \
    tmp/src/title.js \
    tmp/src/axis.js \
    tmp/src/legend.js \
    tmp/src/scale.js \
    tmp/src/scaleset.js \
    tmp/src/data.js \
    tmp/src/dataprocess.js \
    tmp/src/layer.js \
    tmp/src/pane.js \
    tmp/src/dim.js \
    tmp/src/render.js \
    tmp/src/interact.js \
    tmp/src/facet.js \
		tmp/src/event.js \
    tmp/src/graph.js > tmp/polychart2.bare.js
	cat $(HEADER) tmp/polychart2.bare.js $(FOOTER) > polychart2.js

polychart2.min: polychart2
	python make/uglify.py --source=polychart2.js --dest=polychart2.min.js

polychart2.standalone: polychart2.min
	awk 'FNR==1{print ";"}1' $(LIBITEMS) polychart2.min.js > polychart2.standalone.js

examples:
	coffee  --compile --output compiled/example/ example/
	cat compiled/example/* > examples.js

tests:
	coffee --compile --output compiled/test/ test/
	cat compiled/test/* > tests.js

clean-folders:
	-rm -r compiled || echo "Done removing compiled/" && false
	-rm -r tmp || echo "Done removing tmp/" && false

clean: clean-folders
	rm $(OBJS)
