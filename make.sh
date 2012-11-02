coffee --compile --output compiled/src/ src/
coffee --compile --output compiled/test/ test/
cat compiled/src/* > polychart2.js
