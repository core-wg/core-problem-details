---
v: 3

title: Concise Problem Details For CoAP APIs
abbrev: CoRE Problem Details
docname: draft-ietf-core-problem-details-latest
category: std
consensus: true
submissiontype: IETF

ipr: trust200902
area: ART
workgroup: CoRE Working Group
keyword: CoAP, API, Problem Details

stand_alone: yes
pi: [toc, sortrefs, symrefs]

author:
 -  name: "Thomas Fossati"
    organization: "arm"
    email: thomas.fossati@arm.com
 -  name: Carsten Bormann
    org: Universität Bremen TZI
    street: Postfach 330440
    city: Bremen
    code: D-28359
    country: Germany
    phone: +49-421-218-63921
    email: cabo@tzi.org

normative:
  STD94:
    -: bis
    =: RFC8949
  STD66:
    -: uri
    =: RFC3986
  RFC7252: coap
  RFC7807: http-problem

--- abstract

This document defines a "problem detail" as a way to carry
machine-readable details of errors in a REST response to avoid the
need to define new error response formats for REST APIs.
The format
is inspired by, but intended to be more concise than, the Problem
Details for HTTP APIs defined in RFC 7807.

--- middle

# Introduction

REST response status information such as CoAP {{-coap}} response
codes is sometimes not sufficient to convey enough information about
an error to be helpful.  This specification defines a simple and
extensible framework to define CBOR tags to suit this purpose.
It is designed to be reused by REST APIs, which can identify distinct
"problem types" specific to their needs.
Thus, API clients can be informed of both the high-level error class
(using the response code) and the finer-grained details of the problem
(using this vocabulary), as shown in {{fig-problem-details}}.

~~~ aasvg
+--------+           +--------+
|  CoAP  |           |  CoAP  |
| Client |           | Server |
+----+---+           +----+---+
     |                    |
     | Request            |
     |------------------> |
     |                    |
     | <----------------- |
     | Error Response     |
     | with a CBOR Data   |
     | Item giving        |
     | Problem Details    |
     |                    |
~~~
{: #fig-problem-details artwork-align="center"
   title="Problem Details: Example with CoAP"}

The framework presented is largely inspired by the Problem Details for HTTP APIs defined in {{RFC7807}}.

## Requirements Language

{::boilerplate bcp14-tagged}

# Basic Problem Details

A Concise Problem Details data item is a CBOR data item with the following
structure (notated in CDDL {{!RFC8610}}, using 65535 in place of a tag number to
be defined for the type of problem details):

~~~ CDDL
problem-details = #6.65535(problem-details-map)
problem-details-map = non-empty<{
  ? &(title: -1) => text
  ? &(detail: -2) => text
  ? &(instance: -3) => ~uri
  standard-problem-detail-entries
  custom-problem-detail-entries
}>
standard-problem-detail-entries = (
  * nint => any
)
custom-problem-detail-entries = (
  * (uint/detail-label) => any
)
detail-label = text .regexp "[^:]+" / ~uri
non-empty<M> = (M) .and ({ + any => any })
~~~
{: #cddl title="Problem Detail Data Item"}

Due to a limitation of the CDDL notation for tags, the problem type
cannot be expressed under this name in CDDL.
It is represented in the tag number, which is shown here as 65535.

One tag has been registered as a generic problem type by this
specification (see {{iana-tag}}).
Further problem types can be defined by registering additional tags (see {{sec-new-attributes}}).

A number of problem detail entries, the Standard Problem Detail
entries, are predefined (more predefined details can be registered,
see {{new-spdk}}):

{:vspace}
The title (key -1):
: A short, human-readable summary of the problem type.
  It SHOULD NOT change from occurrence to occurrence of the problem.

The detail (key -2):
: A human-readable explanation specific to this occurrence of the problem.

The instance (key -3):
: A URI reference that identifies the specific occurrence of the problem.
  It may or may not yield further information if dereferenced.

Consumers MUST use the type (tag number) as primary identifiers for
the problem type; the "title" string is advisory and included only for
consumers who are not aware of the semantics of the CBOR tag number
used to indicate the specific problem type.

The "detail" member, if present, ought to focus on helping the client correct the problem, rather than giving debugging information.  Consumers SHOULD NOT parse the "detail" member for information; extensions (see {{sec-new-attributes}}) are more suitable and less error-prone ways to obtain such information.

Note that the "instance" URI reference may be relative; this means
that it must be resolved relative to the document's base URI, as per
{{-uri}}.

Note that the response code information that may be available together
with a problem report is *not* replicated into a problem detail entry;
compare this with "status" in {{-http-problem}}.

{:aside}
> (**Issue**: Do we still want to define a SPDK for status, so
implementations can easily stash away the response code available from
context into the problem details?)

# Additional Problem Details
{: #sec-new-attributes}

This specification defines a single problem type, the Generic Problem
Details problem type (represented by CBOR tag TBD400, {{iana-tag}}).

## Additional Problem Types

To establish a new problem type, different from the Generic Problem
Details problem type, a CBOR Tag number needs to be
registered in the {{cbor-tags (CBOR Tags)<IANA.cbor-tags}} of {{!IANA.cbor-tags}}.
Note that this registry allows the registration of new tags under the
First Come First Served policy {{?RFC8126}}, making new registrations
available in a simple interaction (e.g., via web or email) with IANA,
after having filled in the small template provided in {{Section 9.2 of
STD94}}.
Such a registration SHOULD provide a documentation reference and also
SHOULD reference the present specification.

## Custom Problem Detail Entries

Problem type definitions MAY extend the Problem Details document with
additional entries to convey additional, problem-type-specific information,
*custom problem details*.
In the definition of a problem type, each custom problem detail
receives a map key specific to this problem type (custom problem detail entry map key, unsigned
integer or text); this SHOULD be described in the documentation that goes
along with the registration of a CBOR Tag for the problem type.

For text detail-labels, a name without an embedded colon can be chosen
instead of an integer custom label, or a detail-label that is a URI.
This URI is for identification purposes only and MUST NOT be
dereferenced in the normal course of handling problem details (i.e.,
outside diagnostic/debugging procedures involving humans).

In summary, the keys for Custom Problem Detail entries are in a
namespace specific to the Problem Type the documentation of which
defines these entries.
Consumers of a Problem Type instance MUST ignore any Custom Problem
Detail entries that they
do not recognize; this allows problem types to evolve and include
additional information in the future.
If, in the evolution of a problem type, a new problem detail is added
that needs to be understood by all consumers, a new problem type needs
to be defined (i.e., problem detail entries are always elective, never
critical, in the terminology of {{Section 5.4.1 of -coap}}).

## Standard Problem Detail Entries {#new-spdk}

Beyond the Standard Problem Detail keys defined in {{cddl}}, additional
Standard Problem Detail keys can be registered (see {{iana-spdk}}).
Standard Problem Detail keys are not specific to a particular problem
type; they are intended to be used for problem details that cover an
area of application that includes multiple registered problem types.

Standard Problem Detail keys are negative integers, so they never can
conflict with Custom Problem Detail keys defined for a problem type
(which are unsigned integers or text strings).

In summary, the keys for Standard Problem Detail entries are in a
global namespace that applies to all Problem Types.
The documentation of a Problem Type MAY provide additional guidance on
how a Standard Problem Detail entry applies to this Problem Type, but
cannot redefine its generic semantics.

Therefore, clients consuming problem details may be able to consume unknown
Problem types (i.e., with unknown CBOR Tag numbers), if the general
context (e.g., a media type known from the context such as that
defined in {{media-type}}) indicates that the present specification is used.
Such consumers MUST ignore any Standard Problem Detail entries that
they do not recognize (which, for an unknown tag, by definition also
applies to all Custom Problem Details entries).

# Security Considerations {#seccons}

The security and privacy considerations outlined in Section 5 of {{RFC7807}} apply in full.

# IANA Considerations

[^to-be-removed]

[^to-be-removed]: RFC Editor: please replace RFC XXXX with this RFC number and remove this note.

## CBOR Tag {#iana-tag}

As per {{STD94}}, IANA has created a "{{cbor-tags (CBOR
Tags)<IANA.cbor-tags}}" registry {{IANA.cbor-tags}},
which serves as the registry for problem details types (see {{sec-new-attributes}}).
For use as a predefined, generic problem details type,
IANA is requested to allocate the tag defined in {{tab-tag-values}}.

| Tag    | Data Item | Semantics               | Reference |
| TBD400 | map       | Generic Problem Details | RFCXXXX   |
{: #tab-tag-values align='left'  title="Generic Problem Details tag"}

## Standard Problem Detail Key registry {#iana-spdk}

<!-- {{content-formats (CoAP Content-Formats)<IANA.core-parameters}} -->

This specification defines a new sub-registry for Standard Problem
Detail Keys in the CoRE Parameters registry {{!IANA.core-parameters}},
with the policy "specification required" {{!RFC8126}}.

Each entry in the registry must include:

{:vspace}
key value:
: a negative integer to be used as the value of the key

name:
: a name that could be used in implementations for the key

type:
: type of the data associated with the key; preferably in CDDL
  notation

brief description:
: a brief description

reference:
: a reference document

Initial entries in this sub-registry are as follows:

| Key value | Name     | Type | Brief Description                                                     | Reference |
|        -1 | title    | text | short, human-readable summary of the problem type                     | RFCXXXX   |
|        -2 | detail   | text | human-readable explanation specific to this occurrence of the problem | RFCXXXX   |
|        -3 | instance | ~uri | URI reference identifying specific occurrence of the problem          | RFCXXXX   |
{: #spdk title="Initial Entries in Standard Problem Detail Key registry"}

## Media Type

IANA is requested to add the following Media-Type to the "Media Types"
registry {{!IANA.media-types}}.

| Name                         | Template                                 | Reference              |
| concise-problem-details+cbor | application/concise-problem-details+cbor | RFCXXXX, {{media-type}} |
{: #new-media-type align="left" title="New Media Type application/concise-problem-details+cbor"}

{:compact}
Type name:
: application

Subtype name:
: concise-problem-details+cbor

Required parameters:
: none

Optional parameters:
: none

Encoding considerations:
: binary (CBOR data item)

Security considerations:
: {{seccons}} of RFC XXXX

Interoperability considerations:
: none

Published specification:
: {{media-type}} of RFC XXXX

Applications that use this media type:
: Clients and servers in the Internet of Things

Fragment identifier considerations:
: The syntax and semantics of fragment identifiers is as specified for
  "application/cbor".  (At publication of RFC XXXX, there is no
  fragment identification syntax defined for "application/cbor".)

Person & email address to contact for further information:
: CoRE WG mailing list (core@ietf.org),
  or IETF Applications and Real-Time Area (art@ietf.org)

Intended usage:
: COMMON

Restrictions on usage:
: none

Author/Change controller:
: IETF

Provisional registration:
: no

## Content-Format

IANA is requested to register a Content-Format number in the
{{content-formats ("CoAP Content-Formats")<IANA.cbor-tags}}
sub-registry, within the "Constrained RESTful Environments (CoRE)
Parameters" Registry {{IANA.core-parameters}}, as follows:

| Content-Type                             | Content Coding | ID   | Reference |
| application/concise-problem-details+cbor | -              | TBD1 | RFC XXXX  |
{: align="left" title="New Content-Format"}

TBD1 is to be assigned from the space 256..999.

In the registry as defined by {{Section 12.3 of -coap}} at the time of
writing, the column "Content-Type" is called "Media type" and the
column "Content Coding" is called "Encoding".

--- back

# Acknowledgments
{:unnumbered}

{{{Mark Nottingham}}} and {{{Erik Wilde}}}, authors of RFC 7807.
{{{Klaus Hartke}}} and {{{Jaime Jiménez}}}, co-authors of an earlier generation of
this specification.
{{{Christian Amsüss}}} and {{{Marco Tiloca}}} for review and comments on this document.
