# Polychart2.js
rm -r compiled/src/
coffee --compile --output compiled/src/ src/
cat \
    compiled/src/utils.js \
    compiled/src/const.js \
    compiled/src/error.js \
    compiled/src/abstract.js\
    compiled/src/mouse.js \
    compiled/src/format.js \
    compiled/src/type.js \
    compiled/src/spec.js \
    compiled/src/ajax.js \
    compiled/src/parser.js \
    compiled/src/coord.js \
    compiled/src/domain.js \
    compiled/src/tick.js \
    compiled/src/title.js \
    compiled/src/axis.js \
    compiled/src/legend.js \
    compiled/src/scale.js \
    compiled/src/scaleset.js \
    compiled/src/data.js \
    compiled/src/dataprocess.js \
    compiled/src/layer.js \
    compiled/src/pane.js \
    compiled/src/dim.js \
    compiled/src/render.js \
    compiled/src/interact.js \
    compiled/src/facet.js \
    compiled/src/graph.js > compiled/src/polychart2.bare.js
cat make/header.js compiled/src/polychart2.bare.js make/footer.js > polychart2.js

rm polychart2.min.js
python make/uglify.py --source=polychart2.js --dest=polychart2.min.js
rm polychart2.standalone.js
awk 'FNR==1{print ";"}1' lib/underscore.js lib/moment.js lib/raphael.js polychart2.min.js > polychart2.standalone.js

# Unit Tests
rm -r compiled/test/
coffee --compile --output compiled/test/ test/

# Examples
rm -r compiled/example/
coffee --compile --output compiled/example/ example/
cat compiled/example/* > examples.js

