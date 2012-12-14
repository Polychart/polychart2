poly = @poly || {}

class DefinitionError extends Error
  constructor: (@message) ->
    @name = "DefinitionError"

class DependencyError extends Error
  constructor: (@message) ->
    @name = "DependencyError"

class ModeError extends Error
  constructor: (@message) ->
    @name = "ModeError"

class DataError extends Error
  constructor: (@message) ->
    @name = "DataError"

class UnknownInput extends Error
  constructor: (@message) ->
    @name = "UnknownInput"

class NotImplemented extends Error
  constructor: (@message) ->
    @name = "ModeError"

poly.error =
  data: DataError
  depn: DependencyError
  defn: DefinitionError
  mode: ModeError
  impl: NotImplemented
  input: UnknownInput
  unknown: Error

@poly = poly
