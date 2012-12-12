(function() {

  poly.xhr = function(url, mime, callback) {
    var req;
    req = new XMLHttpRequest;
    if (arguments.length < 3) {
      callback = mime;
      mime = null;
    } else if (mime && req.overrideMimeType) {
      req.overrideMimeType(mime);
    }
    req.open("GET", url, true);
    if (mime) req.setRequestHeader("Accept", mime);
    req.onreadystatechange = function() {
      var arg, s;
      if (req.readyState === 4) {
        s = req.status;
        arg = !s && req.response || s >= 200 && s < 300 || s === 304 ? req : null;
        return callback(arg);
      }
    };
    return req.send(null);
  };

  poly.text = function(url, mime, callback) {
    var ready;
    ready = function(req) {
      return callback(req && req.responseText);
    };
    if (arguments.length < 3) {
      callback = mime;
      mime = null;
    }
    return poly.xhr(url, mime, ready);
  };

  poly.json = function(url, callback) {
    return poly.text(url, "application/json", function(text) {
      return callback(text ? JSON.parse(text) : null);
    });
  };

  poly.dsv = function(delimiter, mimeType) {
    var delimiterCode, dsv, formatRow, formatValue, header, reFormat, reParse;
    reParse = new RegExp("\r\n|[" + delimiter + "\r\n]", "g");
    reFormat = new RegExp("[\"" + delimiter + "\n]");
    delimiterCode = delimiter.charCodeAt(0);
    formatRow = function(row) {
      return row.map(formatValue).join(delimiter);
    };
    formatValue = function(text) {
      var _ref;
      return (_ref = reFormat.test(text)) != null ? _ref : "\"" + text.replace(/\"/g, "\"\"") + {
        "\"": text
      };
    };
    header = null;
    dsv = function(url, callback) {
      return poly.text(url, mimeType, function(text) {
        return callback(text && dsv.parse(text));
      });
    };
    dsv.parse = function(text) {
      return dsv.parseRows(text, function(row, i) {
        var item, j, m, o;
        if (i) {
          o = {};
          j = -1;
          m = header.length;
          while (++j < m) {
            item = row[j];
            o[header[j]] = row[j];
          }
          return o;
        } else {
          header = row;
          return null;
        }
      });
    };
    dsv.parseRows = function(text, f) {
      var EOF, EOL, a, eol, n, rows, t, token;
      EOL = {};
      EOF = {};
      rows = [];
      n = 0;
      t = null;
      eol = null;
      reParse.lastIndex = 0;
      token = function() {
        var c, i, j, m;
        if (reParse.lastIndex >= text.length) return EOF;
        if (eol) {
          eol = false;
          return EOL;
        }
        j = reParse.lastIndex;
        if (text.charCodeAt(j) === 34) {
          i = j;
          while (i++ < text.length) {
            if (text.charCodeAt(i) === 34) {
              if (text.charCodeAt(i + 1) !== 34) break;
              i++;
            }
          }
          reParse.lastIndex = i + 2;
          c = text.charCodeAt(i + 1);
          if (c === 13) {
            eol = true;
            if (text.charCodeAt(i + 2) === 10) reParse.lastIndex++;
          } else if (c === 10) {
            eol = true;
          }
          return text.substring(j + 1, i).replace(/""/g, "\"");
        }
        m = reParse.exec(text);
        if (m) {
          eol = m[0].charCodeAt(0) !== delimiterCode;
          return text.substring(j, m.index);
        }
        reParse.lastIndex = text.length;
        return text.substring(j);
      };
      while ((t = token()) !== EOF) {
        a = [];
        while (t !== EOL && t !== EOF) {
          a.push(t);
          t = token();
        }
        if (f && !(a = f(a, n++))) continue;
        rows.push(a);
      }
      return rows;
    };
    dsv.format = function(rows) {
      return rows.map(formatRow).join("\n");
    };
    return dsv;
  };

  poly.csv = poly.dsv(",", "text/csv");

}).call(this);
