poly = @poly || {}

# EXCEPTIONS
class NotImplemented extends Error
  constructor: (@message = "Not implemented") ->
    @name = "NotImplemented"
poly.NotImplemented = NotImplemented

class UnexpectedObject extends Error
  constructor: (@message = "Unexpected Object") ->
    @name = "UnexpectedObject"
poly.UnexpectedObject = UnexpectedObject

class StrictModeError extends Error
  constructor: (@message = "Can't use strict mode here") ->
    @name = "StrictModeError"
poly.StrictModeError = StrictModeError

class LengthError extends Error
  constructor: (@message = "Unexpected length") ->
    @name = "LengthError"
poly.LengthError = LengthError

class UnknownError extends Error
  constructor: (@message = "Unknown error") ->
    @name = "UnknownError"
poly.UnknownError = UnknownError