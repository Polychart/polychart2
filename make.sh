rm -r compiled/src/
coffee --compile --output compiled/src/ src/
rm -r compiled/test/
coffee --compile --output compiled/test/ test/
cat compiled/src/utils.js \
    compiled/src/const.js \
    compiled/src/exceptions.js \
    compiled/src/domain.js \
    compiled/src/tick.js \
    compiled/src/guide.js \
    compiled/src/scale.js \
    compiled/src/data.js \
    compiled/src/layer.js \
    compiled/src/dim.js \
    compiled/src/render.js \
    compiled/src/graph.js > polychart2.js
