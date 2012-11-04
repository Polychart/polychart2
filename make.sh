rm -r compiled/src/
coffee --compile --output compiled/src/ src/
rm -r compiled/test/
coffee --compile --output compiled/test/ test/
cat compiled/src/utils.js compiled/src/scale.js compiled/src/* > polychart2.js
