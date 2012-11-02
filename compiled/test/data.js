(function() {

  module("FOO");

  test("BAR", function() {
    var foo;
    foo = new Data(2);
    return equal(foo.input, 2);
  });

}).call(this);
