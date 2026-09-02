# Feature #77 — Stakeholder Input

Verbatim. Source: original ticket and stakeholder clarification.

---

## Original ticket

A better REPL model, more consistent with the rest of the
controls, with callbacks. I.e. setting up an edit area with
an optional non-empty content, syntax highlighter and input
validator and receiving callbacks on the user entering
something on it.

## Owner clarification

1. It is certainly not an exhaustive feature list. Basically,
   what I would like to see is an API that allows for an easy
   implementation of interfaces that are similar to either the
   command console or the editor. Ideally, these should also be
   re-implemented using the same API. What I'd like to see in
   addition to features mentioned in the ticket are callbacks
   for keys pressed together with the Ctrl key or keys that do
   not insert or remove a symbol in the edit area.
   Unfortunately, function keys (the ones in the top row of the
   keyboard) only work with external keyboard, the internal ones
   are hijacked by the OS. Another thing, I'd like to see a
   callback for is cursor movements that "hit a wall", trying
   to move the cursor past the beginning or the end of the edit
   area and, of course, entering a line. Calls should be
   provided for setting up an edit area (with an optional
   initial text, cursor position, highlighter and verifier) and
   for removing the edit area, for querying and changing the
   cursor's position, and changing the text.

   (I might have forgotten something, but see the principles
   spelled out in the beginning)

2. Games and other examples already in development or even
   ready (like tixy), REPL dialogs, text-based adventure games,
   etc. The biggest problem with the current API is that it is
   inconsistent with the rest of love, handling keyboard events
   in parallel to editing is a PITA and it is not easy to hide
   or show the input area (see your struggles in sapper).


## FEEDBACK AFTER FIRST ITERATION (ongoing)

### D-1 discarded: no backward compatibility required

#### Citation 1 

Stakeholder1:

Is there any benefit to maintaining backwards compatibility of the input API? We know all the software that uses it and it all must be updated anyway (and will greatly benefit from doing so).


In this case [context: D-1], I disagree. The examples are examples, showing how to write code. Leaving legacy API use in a release defeats the very purpose. There are not that many of them and each and every one would be radically shorter and simpler after updating to the use of the new API.

The only examples where there is a time pressure on the release are the ones that we might want to use <REDACTED>, such as maze and balloons. I am very fond of tixy as a showcase, so that might also need updating. But that's it. For all the other examples, we can just exclude them from the next release, if we don't have the time to convert them to the new API. Even tixy can be left out, if absolutely necessary.

Some of the examples, such as basic REPL games, are actually trivial to convert (or even rewrite from scratch).

So, I am strongly in favor of getting rid of the legacy API, ASAP.


Stakeholder 2: 
We are before 1.0, there's absolutely no need to maintain backwards compatibility

Stakeholder 3:
We really shouldn't go from having an almost-good ... experience to not having any, even temporarily, because we don't know how long updating all programs will actually take and how many crippling bugs we'll discover in the process.

Stakeholder 1: > S3

I don't think that it reduces any risk. I stronly disagree.

S2: 
the old releases will still exist, the existing experience is not deleted

S3:
Right now the games that can be used and enhance ... experience are: <6 games not in repo>, tixy

S1:
Only <...> and tixy have text inputs from that list.

S3: 
This won't break all keyboard input, only text fields?

S1:
You don't upgrade before testing the new version.

S1:
Only text fields.

S3:
Okay, then it's less of a problem.

(CONSENSUS REACHED: D-1 DISCARDED)
