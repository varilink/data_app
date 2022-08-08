# facebook-events.pl

This script implements integration of the DATA Diary with the pages associated
with the Derby Arts and Theatre Association's Facebook business account. It does
this via a DATA Diary Facebook application.

The Derby Arts and Theatre Association's Facebook business account has two
pages:

- Derby Arts & Theatre Association

    Public page for Derby Arts and Theatre Association

- Derby Arts and Theatre Association - Testing

    Private (unpublished) page for Derby Arts and Theatre Association that can be
    used for testing

## Parameters

In production use this script is run without parameters. For testing purposes
though, parameters can be supplied as follows:

- -d

    Turn debugging on. This enables the output of more messages than will be output
    with debugging off.

- -t offset\_days \[offset\_hours\]

    Time offset, which can be used to offset the current time so that events become
    eligible for posting when that wouldn't otherwise be the case. At least one and
    up to two integers can follow this flag, the first is the number of offset days
    and the second is the number of offset hours. Either can be positive, which
    moves the time in to the future, or negative, which moves it in to the past. To
    enter offset hours without offset days set the offset days to 0 and follow with
    the offset hours.
