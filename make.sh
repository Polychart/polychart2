rm -r compiled/src/
coffee --compile --output compiled/src/ src/
cat compiled/src/utils.js \
    compiled/src/const.js \
    compiled/src/exceptions.js \
    compiled/src/spec.js \
    compiled/src/coord.js \
    compiled/src/domain.js \
    compiled/src/tick.js \
    compiled/src/guide.js \
    compiled/src/scale.js \
    compiled/src/data.js \
    compiled/src/layer.js \
    compiled/src/dim.js \
    compiled/src/render.js \
    compiled/src/graph.js > polychart2.js
rm -r compiled/test/
coffee --compile --output compiled/test/ test/
rm -r compiled/example/
coffee --compile --output compiled/example/ example/
cat compiled/example/* > examples.js

