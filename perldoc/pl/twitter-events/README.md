# twitter-events

This script tweets about events on behalf of Derby Arts and Theatre Association.

## Parameters

In production use this script is run without parameters. For testing purposes
though, parameters can be supplied as follows:

- -d

    Turn debugging on. This enables the output of more messages than will be output
    with debugging off.

- -t offset\_days \[offset\_hours\]

    Time offset, which can be used to offset the current time so that events become
    eligible for Tweeting when that wouldn't otherwise be the case. Up to two
    integers can follow this flag, the first is the number of offset days and the
    second is the number of offset hours. Either can be positive, which moves the
    time in to the future, or negative, which moves it in to the past.
