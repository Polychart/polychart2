(function() {
  var DataError, DefinitionError, DependencyError, ModeError, NotImplemented, UnknownInput, poly,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  poly = this.poly || {};

  DefinitionError = (function(_super) {

    __extends(DefinitionError, _super);

    function DefinitionError(message) {
      this.message = message;
      this.name = "DefinitionError";
    }

    return DefinitionError;

  })(Error);

  DependencyError = (function(_super) {

    __extends(DependencyError, _super);

    function DependencyError(message) {
      this.message = message;
      this.name = "DependencyError";
    }

    return DependencyError;

  })(Error);

  ModeError = (function(_super) {

    __extends(ModeError, _super);

    function ModeError(message) {
      this.message = message;
      this.name = "ModeError";
    }

    return ModeError;

  })(Error);

  DataError = (function(_super) {

    __extends(DataError, _super);

    function DataError(message) {
      this.message = message;
      this.name = "DataError";
    }

    return DataError;

  })(Error);

  UnknownInput = (function(_super) {

    __extends(UnknownInput, _super);

    function UnknownInput(message) {
      this.message = message;
      this.name = "UnknownInput";
    }

    return UnknownInput;

  })(Error);

  NotImplemented = (function(_super) {

    __extends(NotImplemented, _super);

    function NotImplemented(message) {
      this.message = message;
      this.name = "ModeError";
    }

    return NotImplemented;

  })(Error);

  poly.error = {
    data: DataError,
    depn: DependencyError,
    defn: DefinitionError,
    mode: ModeError,
    impl: NotImplemented,
    input: UnknownInput,
    unknown: Error
  };

  this.poly = poly;

}).call(this);
