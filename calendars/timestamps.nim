## This module contains routines and types for dealing with time, calendars and timezones.
##
## Examples:
##
## .. code-block:: nim
##
##  import moment
##
##
## There are two ways to represent time with moment, Timestamp and Calendar
##
## Timestamp is just a float64 number of seconds since 1970 UTC. This is very fast way to deal with time and is recommened to store and use your times with this.
##
## Calendar is a full data structure that has time, date and timezone info parsed out. You can use if you have to, but it is recommended to use Timestamp for most operations.
##
## Dealing with timezones and DST. If you can get a way with just using UTC you should. Dealing with timzones is not fun.
## If there is a known timezone, parseTs with that timzone. Then timezone is thrown a way.
## When you need to display time back, chanses are its a different time zone so just format the number with that timezone.
##


import strutils

import ../calendars

type
  Timestamp* = distinct float64


proc `==`*(a, b: Timestamp): bool = float64(a) == float64(b)
proc `>`*(a, b: Timestamp): bool = float64(a) > float64(b)
proc `<`*(a, b: Timestamp): bool = float64(a) < float64(b)
proc `<=`*(a, b: Timestamp): bool = float64(a) <= float64(b)
proc `>=`*(a, b: Timestamp): bool = float64(a) >= float64(b)
proc `$`*(a: Timestamp): string = $float64(a)


proc tsToCalendar*(ts: Timestamp): Calendar =
  ## Converts a Timestamp to a Calendar
  var tss: int64 = int(ts)

  if float64(ts) < 0:
    # TODO this works but is kind of a hack to support negative ts
    tss += 62167132800 # seconds from 0 to 1970
    if tss < 0:
      return

  result.secondFraction = float64(ts) - float64(tss)
  var s = tss mod 86400
  tss = tss div 86400
  var h = s div 3600
  var m = s div 60 mod 60
  s = s mod 60
  var
    x = (tss * 4 + 102032) div 146097 + 15
    b = tss + 2442113 + x - (x div 4)
    c = (b * 20 - 2442) div 7305
    d = b - 365 * c - c div 4
    e = d * 1000 div 30601
    f = d - e * 30 - e * 601 div 1000
  result.second = int s
  result.minute = int m
  result.hour = int h
  result.day = int f
  if e < 14:
    result.month = int e - 1
    result.year = int c - 4716
  else:
    result.month = int e - 13
    result.year = int c - 4715

  if float64(ts) < 0:
    # TODO this works but is kind of a hack to support negative ts
    result.year -= 1970


proc calendarToTimestamp*(cal: Calendar): Timestamp =
  ## Converts Calendar to a Timestamp

  var m = cal.month
  var y = cal.year
  if m <= 2:
     y -= 1
     m += 12
  var yearMonthPart = 365 * y + y div 4 - y div 100 + y div 400 + 3 * (m + 1) div 5 + 30 * m
  var tss = (yearMonthPart + cal.day - 719561) * 86400 + 3600 * cal.hour + 60 * cal.minute + cal.second
  return Timestamp(float64(tss) + cal.secondFraction - cal.tzOffset)


proc tsToCalendar*(ts: Timestamp, tzOffset: float64): Calendar =
  ## Converts a Timestamp to a Calendar with a tz offset. Does not deal with DST.

  var tsTz = float64(ts) + tzOffset
  result = tsToCalendar(Timestamp(tsTz))
  result.tzOffset = tzOffset


proc tsToIso*(ts: Timestamp): string =
  ## Fastest way to convert Timestamp to an ISO 8601 string representaion
  ## Use this instead of the format function when dealing whith ISO format
  return calendarToIso(tsToCalendar(ts))


proc tsToIso*(ts: Timestamp, tzOffset: float64): string =
  ## Fastest way to convert Timestamp to an ISO 8601 string representaion
  ## Use this instead of the format function when dealing whith ISO format
  return calendarToIso(tsToCalendar(ts, tzOffset))


proc isoToTimestamp*(iso: string): Timestamp =
  ## Fastest way to convert an ISO 8601 string representaion to a Timestamp.
  ## Use this instead of the parseTimestamp function when dealing whith ISO format
  return calendarToTimestamp(isoToCalendar(iso))


#[
proc parseTime*(fmt: string, str: string): Timestamp =
  # dd
  return 0.0

proc parseTime*(fmt: string): Timestamp =
  # default ISO format
  return 0.0

proc formatTime*(moment: Timestamp): string =
  # default ISO format
  return ""

proc formatTime*(moment: Timestamp, fmt: string): string =
  # user format
  return ""

proc formatTimeDelat*(dt: float): string =
  # delta foramt
  return ""
]#
