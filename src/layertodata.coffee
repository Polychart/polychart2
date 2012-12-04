###
var layerSpec = {
  data: DATA_SET,
  type: “point”,
  y: {var: “b”, sort: “a”, guide: “y2”},
  x: “a”,
  color: {const: “blue”},
  opacity: {var: “sum(c)”},
  filter: { x: { gt: 0, lt: 100 } },
}


var dataSpec = {
  trans: [{key: “a”, trans: “bin”, binwidth: 10, name: “bin(a,10)”},
          {key: “b”, trans: “lag”, lag: 1, name: “lag(b, 1)”},
          ...],
  filter: {a: { gt: 0, le: 100},
           c: { in: [“group1”, “group2”, “group3”]},
           ... },
  stats: {stats:
            [{key: “b”, stat: “mean”, name: “mean(b)”},
             {key: “e”, stat: “count”, name: “count(e)”},
             ...],
          groups: [“bin(a,10)”, “c”]},
  select: [“bin(a,10)”, “bin(b,5)”, “mean(b)”, “count(e)”, “c”],
  meta: {
    c: { sort: “count(e)”
         stat: {key: “e”, stat: “count”, name: “count(e)”},
         limit: 3,
         asc: true},
    f: { limit: 3,
         asc: false},
  }
}
###


