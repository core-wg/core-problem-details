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
 -  name: Thomas Fossati
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
contributor:
 -  name: Peter Occil
    email: poccil14 at gmail dot com
    uri: http://peteroupc.github.io/CBOR/
    contribution: Peter defined CBOR tag 38, basis of {{tag38}}.

venue:
  group: Constrained RESTful Environments
  mail: core@ietf.org
  github: core-wg/core-problem-details

normative:
  STD94:
    -: cbor
    =: RFC8949
  STD66:
    -: uri
    =: RFC3986
  RFC7252: coap
  RFC7807: http-problem
  IANA.cbor-tags: tags
  RFC5646: bcp-47-3
  RFC4647: bcp-47-4
  RFC8610: cddl
  RFC9165: cddlplus
informative:
#  W3C.REC-rdf-concepts-20040210: rdf
  RFC4648: base
  I-D.ietf-httpapi-rfc7807bis: 7807bis
  RDF: # 2
    -: rdf
    target: http://www.w3.org/TR/2014/REC-rdf11-concepts-20140225/
    author:
      - name: Richard Cyganiak
      - name: David Wood
      - name: Markus Lanthaler
    title: RDF 1.1 Concepts and Abstract Syntax
    rc: W3C Recommendation
    date: 2014-02-25
  Unicode-14.0.0:
    -: unicode
    target: https://www.unicode.org/versions/Unicode14.0.0/
    title: The Unicode Standard, Version 14.0.0
    author:
    - org: The Unicode Consortium
    date: 2021-09
    seriesinfo:
      ISBN: 978-1-936213-29-0
    refcontent:
    - 'Mountain View: The Unicode Consortium'
    ann: >
      Note that while this document references a version that was recent
      at the time of writing, the statements made based on this
      version are expected to remain valid for future versions.

--- abstract

This document defines a "problem detail" as a way to carry
machine-readable details of errors in a REST response to avoid the
need to define new error response formats for REST APIs.
The format
is inspired by, but intended to be more concise than, the Problem
Details for HTTP APIs defined in RFC 7807.

--- middle

# Introduction

REST response status information such as CoAP response
codes ({{Section 5.9 of -coap}}) is sometimes not sufficient to convey enough information about
an error to be helpful.  This specification defines a simple and extensible
framework to define CBOR {{-cbor}} data items to suit this purpose.
It is designed to be reused by REST APIs, which can identify distinct
shapes of these data items specific to their needs.
Thus, API clients can be informed of both the high-level error class
(using the response code) and the finer-grained details of the problem
(using this vocabulary), as shown in {{fig-problem-details}}.

~~~ aasvg
.--------.          .--------.
|  CoAP  |          |  CoAP  |
| Client |          | Server |
'----+---'          '---+----'
     |                  |
     | Request          |
     o----------------->|
     |                  | (failure)
     |<-----------------o
     |   Error Response |
     |      with a CBOR |
     | data item giving |
     |  Problem Details |
     |                  |
~~~
{: #fig-problem-details artwork-align="center"
   title="Problem Details: Example with CoAP"}

The framework presented is largely inspired by the Problem Details for HTTP APIs defined in {{RFC7807}}.
{{comp7807}} discusses applications where interworking with {{RFC7807}} is required.

## Terminology and Requirements Language

The terminology from {{-coap}} and {{-cbor}} applies.
Readers are also expected to be familiar with the terminology from {{-http-problem}}.

In this document, the structure of data is specified in CDDL {{-cddl}} {{-cddlplus}}.

{::boilerplate bcp14-tagged}

# Basic Problem Details

A Concise Problem Details data item is a CBOR data item with the following
structure:

~~~ cddl
problem-details = non-empty<{
  ? &(title: -1) => oltext
  ? &(detail: -2) => oltext
  ? &(instance: -3) => ~uri
  ? &(response-code: -4) => uint .size 1
  standard-problem-detail-entries
  custom-problem-detail-entries
}>

standard-problem-detail-entries = (
  * nint => any
)

custom-problem-detail-entries = (
  * (uint/~uri) => { + any => any }
)

non-empty<M> = (M) .and ({ + any => any })

oltext = text / tag38 ; see Appendix A for tag38

~~~
{: #cddl title="Structure of Concise Problem Details Data Item"}

A number of problem detail entries, the Standard Problem Detail
entries, are predefined (more predefined details can be registered,
see {{new-spdk}}).

Note that, unlike {{RFC7807}}, Concise Problem Details data items have
no explicit "problem type".
Instead, the category (or, one could say, Gestalt) of the problem can
be understood from the shape of the problem details offered, we talk of
a "problem shape" for short.

{:vspace}
The title (key -1):
: A short, human-readable summary of the problem shape.
  It SHOULD NOT change from occurrence to occurrence of the same
  problem shape.

The detail (key -2):
: A human-readable explanation specific to this occurrence of the problem.

The instance (key -3):
: A URI reference that identifies the specific occurrence of the problem.
  It may or may not yield further information if dereferenced.

The response-code (key -4)
: The CoAP response code ({{Sections 5.9 and 12.1.2 of -coap}}) generated by the origin
  server for this occurrence of the problem.

Both "title" and "detail" can use either an unadorned CBOR text string
(`text`) or a language-tagged text string (`tag38`); see {{tag38}} for
the definition of the latter.

The "title" string is advisory and included to give
consumers a shorthand for the category (problem shape) of the error encountered.

The "detail" member, if present, ought to focus on helping the client correct the problem, rather than giving debugging information.  Consumers SHOULD NOT parse the "detail" member for information; extensions (see {{sec-new-attributes}}) are more suitable and less error-prone ways to obtain such information.

Note that the "instance" URI reference may be relative; this means
that it must be resolved relative to the representation's base URI, as
per {{Section 5 of -uri}}.

Note that the "response code" value is a numeric representation of the
actual code (see {{Section 3 of -coap}}), so it does not take the usual form that resembles an
HTTP status code — `4.04 Not found` is represented by the number 132.

# Extending Concise Problem Details
{: #sec-new-attributes}

This specification defines a generic problem details container with only a
minimal set of attributes to make it usable.

It is expected that applications will extend the base format by defining new
attributes.

These new attributes fall into two categories: generic and application
specific.

Generic attributes will be allocated in the `standard-problem-detail-entries`
slot according to the registration procedure defined in {{new-spdk}}.

Application-specific attributes will be allocated in the
`custom-problem-detail-entries` slot according to the procedure described in
{{new-cpdk}}.

## Standard Problem Detail Entries {#new-spdk}

Beyond the Standard Problem Detail keys defined in {{cddl}}, additional
Standard Problem Detail keys can be registered for use in the
`standard-problem-detail-entries` slot (see {{iana-spdk}}).

Standard Problem Detail keys are negative integers, so they can never
conflict with Custom Problem Detail keys defined for a specific
application domain
(which are unsigned integers or URIs.)

In summary, the keys for Standard Problem Detail entries are in a
global namespace that is not specific to a particular application domain.

Consumers of a Concise Problem Details data item MUST ignore any Standard Problem
Detail entries that they do not recognize; this allows problem details to evolve.

## Custom Problem Detail Entries {#new-cpdk}

Applications may extend the Problem Details data item with
additional entries to convey additional, application-specific information.

Such new entries are allocated in the `custom-problem-detail-entries` slot, and
carry a nested map specific to that application.  The map key can either be
an (absolute!) URI (controlled by the entity defining this extension),
or an unsigned integer.
Only the latter needs to be registered ({{iana-cpdk}}).

Within the nested map, any number of attributes can be given for a
single extension.
The semantics of each custom attribute MUST be described in the
documentation for the extension; for extensions that are registered
(i.e., are identified by an unsigned int) that documentation goes
along with the registration.

The unsigned integer form allows a more compact representation.
In
exchange, authors are expected to comply with the required
registration and documentation process.
In comparison, the URI form is less space-efficient but requires no
registration.  It is therefore useful for experimenting during the development
cycle and for applications deployed in environments where producers and
consumers of Concise Problem Details are more tightly integrated.
(The URI form thus covers the potential need we might otherwise have for a "private use" range for the unsigned integers.)

Note that the URI given for the extension is for identification
purposes only and, even if dereferenceable in principle, it MUST NOT be
dereferenced in the normal course of handling problem details (i.e., outside
diagnostic/debugging procedures involving humans).

An example of a custom extension using a URI as `custom-problem-detail-entries`
key is shown in {{fig-example-custom-with-uri}}.

~~~ cbor-diag
{
  / title /         -1: "title of the error",
  / detail /        -2: "detailed information about the error",
  / instance /      -3: "coaps://pd.example/FA317434",
  / response-code / -4: 128, / 4.00 /

  "tag:3gpp.org,2022-03:TS29112": {
    / cause /  0: "machine readable error cause",
    / invalidParams / 1: [
      [
        / param / "first parameter name",
        / reason / "must be a positive integer"
      ],
      [
        / param / "second parameter name"
      ]
    ],
    / supportedFeatures / 2: "d34db33f"
  }
}
~~~
{: #fig-example-custom-with-uri artwork-align="center"
   title="Example Extension with URI key"}

Obviously, an SDO like 3GPP can also easily register such a custom
problem detail entry to receive a more efficient unsigned integer key;
the same example but using a registered unsigned int as
`custom-problem-detail-entries` key is shown in
{{fig-example-custom-with-uint}}.

~~~ cbor-diag
{
  / title /         -1: "title of the error",
  / detail /        -2: "detailed information about the error",
  / instance /      -3: "coaps://pd.example/FA317434",
  / response-code / -4: 128, / 4.00 /

  /example value 4711 not actually registered like this:/
  4711: {
    / cause /  0: "machine readable error cause",
    / invalidParams / 1: [
      [
        / param / "first parameter name",
        / reason / "must be a positive integer"
      ],
      [
        / param / "second parameter name"
      ]
    ],
    / supportedFeatures / 2: "d34db33f"
  }
}
~~~
{: #fig-example-custom-with-uint artwork-align="center"
   title="Example Extension with unsigned int (registered) key"}

In summary, the keys for the maps used inside Custom Problem Detail
entries are defined specifically to the identifier of that Custom Problem Detail
entry, the documentation of which defines these internal entries,
typically chosen to address a given application domain.

Consumers of a Concise Problem Details data item MUST ignore any Custom
Problem Detail entries, or keys inside the Custom Problem Detail
entries, that they do not recognize; this allows Custom Problem Detail
entries to evolve and include additional information in the future.
The assumption is that this is done in a backward and forward
compatible way.

Sometimes, Custom Problem Detail entries can evolve in a way where
forward compatibility by "ignore unknown" would not be appropriate:
e.g., when needing to add a "must-understand" member, which can only
be ignored at the peril of misunderstanding the Concise Problem
Details data item ("false interoperability").
In this case, a new Custom Problem Detail key can simply be
registered for this case, keeping the old key backward and
forward-compatible.

# Security Considerations {#seccons}

The security and privacy considerations outlined in Section 5 of {{RFC7807}} apply in full.

# IANA Considerations

[^to-be-removed]

[^to-be-removed]: RFC Editor: please replace RFC XXXX with this RFC number and remove this note.

## Standard Problem Detail Key registry {#iana-spdk}

<!-- {{content-formats (CoAP Content-Formats)<IANA.core-parameters}} -->

This specification defines a new sub-registry for Standard Problem
Detail Keys in the CoRE Parameters registry {{!IANA.core-parameters}},
with the policy "specification required" {{!RFC8126}}.

Each entry in the registry must include:

{:vspace}
Key value:
: a negative integer to be used as the value of the key

Name:
: a name that could be used in implementations for the key

CDDL type:
: type of the data associated with the key in CDDL notation

Brief description:
: a brief description

reference:
: a reference document

Initial entries in this sub-registry are as follows:

| Key value | Name | CDDL Type | Brief description | Reference |
| -1 | title | text | short, human-readable summary of the problem shape | RFC XXXX |
| -2 | detail | text | human-readable explanation specific to this occurrence of the problem | RFC XXXX |
| -3 | instance | ~uri | URI reference identifying specific occurrence of the problem | RFC XXXX |
| -4 | response-code | uint .size 1 | CoAP response code | RFC XXXX |
{: #spdk title="Initial Entries in the Standard Problem Detail Key registry"}

## Custom Problem Detail Key registry {#iana-cpdk}

This specification defines a new sub-registry for Custom Problem
Detail Keys in the CoRE Parameters registry {{!IANA.core-parameters}},
with the policy "first come first served" {{!RFC8126}}.

Each entry in the registry must include:

{:vspace}
Key value:
: an unsigned integer to be used as the value of the key

Name:
: a name that could be used in implementations for the key

Brief description:
: a brief description

Reference:
: a reference document that provides a description of the map,
  including a CDDL description, that describes all inside keys and
  values

Initial entries in this sub-registry are as follows:

| Key value | Name          |  Brief description                                                     | Reference |
|      7807 | tunnel-7807   |  Carry RFC 7807 problem details in a Concise Problem Details data item | RFC XXXX   |
{: #cpdk title="Initial Entries in Custom Problem Detail Key registry"}


## Media Type

IANA is requested to add the following Media-Type to the "Media Types"
registry {{!IANA.media-types}}.

| Name                         | Template                                 | Reference              |
| concise-problem-details+cbor | application/concise-problem-details+cbor | RFC XXXX, {{media-type}} |
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
{{content-formats ("CoAP Content-Formats")<IANA.core-parameters}}
sub-registry, within the "Constrained RESTful Environments (CoRE)
Parameters" Registry {{IANA.core-parameters}}, as follows:

| Content-Type                             | Content Coding | ID   | Reference |
| application/concise-problem-details+cbor | -              | TBD1 | RFC XXXX  |
{: align="left" title="New Content-Format"}

TBD1 is to be assigned from the space 256..999.

In the registry as defined by {{Section 12.3 of -coap}} at the time of
writing, the column "Content-Type" is called "Media type" and the
column "Content Coding" is called "Encoding". [^remove]

[^remove]: This paragraph to be removed by RFC editor.

## CBOR Tag 38 {#iana-tag38}

In the registry "{{cbor-tags (CBOR Tags)<IANA.cbor-tags}}" {{IANA.cbor-tags}},
IANA has registered CBOR Tag 38.
IANA is requested to replace the reference for this registration with
{{tag38}}, RFC XXXX.

--- back

Language-Tagged Strings {#tag38}
=======================

This appendix serves as the archival documentation for CBOR Tag 38, a
tag for serializing language-tagged text strings in CBOR.
The text of this appendix is adapted from the specification text
supplied for its initial registration.
It has been extended to allow supplementing the language tag by a
direction indication.

Introduction
------------

In some cases it is useful to specify the natural language of a text
string.  This specification defines a tag that does just that.  One
technology that supports language-tagged strings is the Resource
Description Framework (RDF) {{-rdf}}.

Detailed Semantics
------------------

A language-tagged string in CBOR has the tag 38 and consists of an array
with a length of 2 or 3.

The first element is a well-formed language tag under Best Current
Practice 47 ({{-bcp-47-3}} and {{-bcp-47-4}}), represented as a UTF-8 text
string (major type 3).

The second element is an arbitrary UTF-8 text string (major type
3). Both the language tag and the arbitrary string can optionally be
annotated with CBOR tags; this is not shown in the CDDL below.

The optional third element, if present, is a Boolean value that
indicates a direction: `false` for "ltr" direction, `true` for "rtl"
direction.  If the third element is absent, no indication is made
about the direction.

In CDDL:

~~~ cddl
{::include tag38.cddl}
~~~

<!-- RUBY_THREAD_VM_STACK_SIZE=5000000 cddl ... -->

NOTE: Language tags of any combination of case are allowed. But
section 2.1.1 of {{-bcp-47-3}}, part of Best Current Practice 47,
recommends a case combination for language tags, that encoders that
support tag 38 may wish to follow when generating language tags.

Data items with tag 38 that do not meet the criteria above are invalid
(see {{Section 5.3.2 of -cbor}}).

NOTE: The Unicode Standard {{-unicode}} includes a set of characters
designed for tagging text (including language tagging), in the range
U+E0000 to U+E007F. Although many applications, including RDF,
do not disallow these characters in text strings, the Unicode Consortium
has deprecated these characters and recommends annotating language via a
higher-level protocol instead. See the section "Deprecated Tag
Characters" in  Section 23.9 of {{-unicode}}.

Examples
--------

Examples in this section are given in CBOR diagnostic mode, and then
as a pretty-printed hexadecimal representation of the encoded item.

The following example shows how the English-language string "Hello" is
represented.

~~~ cbor-diag
38(["en", "Hello"])
~~~

~~~ cbor-pretty
D8 26               # tag(38)
   82               # array(2)
      62            # text(2)
         656E       # "en"
      65            # text(5)
         48656C6C6F # "Hello"
~~~


The following example shows how the French-language string "Bonjour" is
represented.

~~~ cbor-diag
38(["fr", "Bonjour"])
~~~

~~~ cbor-pretty
D8 26                   # tag(38)
   82                   # array(2)
      62                # text(2)
         6672           # "fr"
      67                # text(7)
         426F6E6A6F7572 # "Bonjour"
~~~

The following example shows how the Hebrew-language string
<u>שלום</u> is represented.
Note the `rtl` direction expressed by setting the third element in the array to "true".

~~~ cbor-diag
38(["he", "שלום", true])
~~~

~~~ cbor-pretty
D8 26                     # tag(38)
   83                     # array(3)
      62                  # text(2)
         6865             # "he"
      68                  # text(8)
         D7A9D79CD795D79D # "שלום"
      F5                  # primitive(21)
~~~

# Interworking with RFC 7807 {#comp7807}

On certain occasions, it will be necessary to carry ("tunnel")
{{RFC7807}} problem details in a Concise Problem Details data item.

This appendix defines a Custom Problem Details entry for that purpose.
This is assigned Custom Problem Detail key 7807 in {{iana-cpdk}}.
Its structure is:

~~~ cddl
tunnel-7807 = {
  ? &(type: 0) => ~uri
  ? &(status: 1) => 0..999
  * text => any
}
~~~

To carry an {{RFC7807}} problem details JSON object in a Concise Problem
Details data item, first convert the JSON object to CBOR as per {{Section
6.2 of -cbor}}.  Create an empty Concise Problem Details data item.

Move the values for "title", "detail", and "instance", if present,
from the {{RFC7807}} problem details to the equivalent Standard Problem
Detail entries.
Create a Custom Problem Details entry with key 7807.
Move the values for "type" and "status", if present, to the equivalent
keys 0 and 1 of the Custom Problem Details entry.
Move all remaining key/value pairs (additional members as per {{Section
3.2 of RFC7807}}) in the converted {{RFC7807}} problem
details object to the Custom Problem Details map unchanged.

The inverse direction, carrying Concise Problem Details in a Problem
Details JSON object requires the additional support provided by
{{-7807bis}}, which is planned to create the HTTP Problem Types
Registry.  An HTTP Problem Type can then be registered that extracts
top-level items from the Concise Problem Details data item in a similar way
to the conversion described above, and which carries the rest of the
Concise Problem Details data item in an additional member via base64url
encoding without padding ({{Section 5 of -base}}).  Details can be defined
in a separate document when the work on {{-7807bis}} is completed.

# Acknowledgments
{:unnumbered}

{{{Mark Nottingham}}} and {{{Erik Wilde}}}, authors of RFC 7807.
{{{Klaus Hartke}}} and {{{Jaime Jiménez}}}, co-authors of an earlier generation of
this specification.
{{{Christian Amsüss}}} and {{{Marco Tiloca}}} for review and comments on this document.

For {{tag38}}, John Cowan and Doug Ewell are also to be acknowledged.
The content of an earlier version of this appendix was also discussed
in the "apps-discuss at ietf.org" and "ltru at ietf.org" mailing
lists.
