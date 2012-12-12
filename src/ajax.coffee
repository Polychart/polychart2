# This code is adapted from d3's CSV code
#
# Copyright (c) 2012, Michael Bostock
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * The name Michael Bostock may not be used to endorse or promote products
#   derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL MICHAEL BOSTOCK BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

poly.xhr = (url, mime, callback) ->
  req = new XMLHttpRequest
  if arguments.length < 3
    callback = mime
    mime = null
  else if mime && req.overrideMimeType
    req.overrideMimeType(mime)
  req.open("GET", url, true)
  if (mime) then req.setRequestHeader("Accept", mime)
  req.onreadystatechange = () ->
    if req.readyState is 4
      s = req.status
      arg =
        if !s && req.response || s >= 200 && s < 300 || s is 304
          req
        else
          null
      callback(arg)
  req.send(null)

poly.text = (url, mime, callback) ->
  ready = (req) -> callback(req && req.responseText)
  if arguments.length < 3
    callback = mime
    mime = null
  poly.xhr(url, mime, ready)

poly.json = (url, callback) ->
  poly.text url, "application/json", (text) ->
    callback(if text then JSON.parse(text) else null)

poly.dsv = (delimiter, mimeType) ->
  reParse = new RegExp("\r\n|[" + delimiter + "\r\n]", "g")
  reFormat = new RegExp("[\"" + delimiter + "\n]")
  delimiterCode = delimiter.charCodeAt(0)
  formatRow = (row) -> row.map(formatValue).join(delimiter)
  formatValue = (text) ->
    reFormat.test(text) ? "\"" + text.replace(/\"/g, "\"\"") + "\"" : text
  header = null

  dsv = (url, callback) ->
    poly.text url, mimeType, (text) -> callback(text && dsv.parse(text))
  dsv.parse = (text) ->
    dsv.parseRows text, (row, i) ->
      if i
        o = {}
        j = -1
        m = header.length
        while (++j < m)
          item = row[j]
          o[header[j]] = row[j]
        return o
      else
        header = row
        return null
  dsv.parseRows = (text, f) ->
    EOL = {}
    EOF = {}
    rows = []
    n = 0
    t = null
    eol = null
    reParse.lastIndex = 0
    token = () ->
      if (reParse.lastIndex >= text.length) then return EOF
      if (eol) then eol = false; return EOL
      j = reParse.lastIndex
      if (text.charCodeAt(j) is 34)
        i = j
        while (i++ < text.length)
          if (text.charCodeAt(i) is 34)
            if (text.charCodeAt(i + 1) isnt 34) then break
            i++
        reParse.lastIndex = i + 2
        c = text.charCodeAt(i + 1)
        if (c is 13)
          eol = true
          if (text.charCodeAt(i + 2) is 10) then reParse.lastIndex++
        else if (c is 10)
          eol = true
        return text.substring(j + 1, i).replace(/""/g, "\"")

      m = reParse.exec(text)
      if (m)
        eol = m[0].charCodeAt(0) isnt delimiterCode
        return text.substring(j, m.index)
      reParse.lastIndex = text.length
      return text.substring(j)

    while ((t = token()) isnt EOF)
      a = []
      while (t isnt EOL && t isnt EOF)
        a.push(t)
        t = token()
      if (f && !(a = f(a, n++))) then continue
      rows.push(a)
    return rows
  dsv.format = (rows) -> rows.map(formatRow).join("\n")
  dsv

poly.csv = poly.dsv(",", "text/csv")
