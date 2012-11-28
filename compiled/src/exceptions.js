(function() {
  var LengthError, NotImplemented, StrictModeError, UnexpectedObject, UnknownError, poly,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  poly = this.poly || {};

  NotImplemented = (function(_super) {

    __extends(NotImplemented, _super);

    function NotImplemented(message) {
      this.message = message != null ? message : "Not implemented";
      this.name = "NotImplemented";
    }

    return NotImplemented;

  })(Error);

  poly.NotImplemented = NotImplemented;

  UnexpectedObject = (function(_super) {

    __extends(UnexpectedObject, _super);

    function UnexpectedObject(message) {
      this.message = message != null ? message : "Unexpected Object";
      this.name = "UnexpectedObject";
    }

    return UnexpectedObject;

  })(Error);

  poly.UnexpectedObject = UnexpectedObject;

  StrictModeError = (function(_super) {

    __extends(StrictModeError, _super);

    function StrictModeError(message) {
      this.message = message != null ? message : "Can't use strict mode here";
      this.name = "StrictModeError";
    }

    return StrictModeError;

  })(Error);

  poly.StrictModeError = StrictModeError;

  LengthError = (function(_super) {

    __extends(LengthError, _super);

    function LengthError(message) {
      this.message = message != null ? message : "Unexpected length";
      this.name = "LengthError";
    }

    return LengthError;

  })(Error);

  poly.LengthError = LengthError;

  UnknownError = (function(_super) {

    __extends(UnknownError, _super);

    function UnknownError(message) {
      this.message = message != null ? message : "Unknown error";
      this.name = "UnknownError";
    }

    return UnknownError;

  })(Error);

  poly.UnknownError = UnknownError;

}).call(this);
