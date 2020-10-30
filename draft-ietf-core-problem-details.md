---
title: Problem Details For CoAP APIs
abbrev: CoRE Problem Details
docname: draft-ietf-core-problem-details-latest
category: std

ipr: trust200902
area: ART
workgroup: CoRE Working Group
keyword: CoAP, API, Problem Details

stand_alone: yes
pi: [toc, sortrefs, symrefs]

author:
 -
    ins: "T. Fossati"
    name: "Thomas Fossati"
    organization: "arm"
    email: thomas.fossati@arm.com
 -
    ins: "J. Jiménez"
    name: "Jaime Jiménez"
    organization: "Ericsson"
    email: jaime@iki.fi

 -
    ins: "K. Hartke"
    name: "Klaus Hartke"
    organization: "Ericsson"
    email: klaus.hartke@ericsson.com

--- abstract

This document defines a "problem detail" as a way to carry machine-readable details of errors in a CoAP response to avoid the need to define new error response formats for CoAP APIs.  The proposed format is inspired by the Problem Details for HTTP APIs defined in RFC 7807.

--- middle

# Introduction

CoAP {{!RFC7252}} response codes are sometimes not sufficient to convey enough information about an error to be helpful.  This specification defines a simple and extensible CoRAL {{!I-D.ietf-core-coral}} vocabulary to suit this purpose.  It is designed to be reused by CoAP APIs, which can identify distinct "problem types" specific to their needs.  Thus, API clients can be informed of both the high-level error class (using the response code) and the finer-grained details of the problem (using this vocabulary), as shown in {{fig-problem-details}}.

~~~
{::include problem-details.ascii-art}
~~~
{: #fig-problem-details artwork-align="center" title="Problem Details"}

The vocabulary presented is largely inspired by the Problem Details for HTTP APIs defined in {{?RFC7807}}.

## Requirements Language

{::boilerplate bcp14}

# Basic Problem Details

A CoRE Problem Details is a CoRAL document with the following elements:

* "type" (id) - The problem type.  This is a mandatory element.
* "title" (text) - A short, human-readable summary of the problem type.  It SHOULD NOT change from occurrence to occurrence of the problem.
* "detail" (text) - A human-readable explanation specific to this occurrence of the problem.
* "instance" (uri) - A URI reference that identifies the specific occurrence of the problem.  It may or may not yield further information if dereferenced.

Consumers MUST use "type" as primary identifiers for the problem type; the "title" string is advisory and included only for consumers who are not aware of the semantics of the "type" value.

The "detail" member, if present, ought to focus on helping the client correct the problem, rather than giving debugging information.  Consumers SHOULD NOT parse the "detail" member for information; extensions (see {{sec-new-attributes}}) are more suitable and less error-prone ways to obtain such information.

Note that the "instance" URI reference may be relative; this means that it must be resolved relative to the document's base URI, as per {{!I-D.ietf-core-coral}}.

## Examples
{: #sec-coral-examples}

This section presents a series of examples of the basic vocabulary in CoRAL textual format (Section 4 of {{!I-D.ietf-core-coral}}).  The examples are fictitious.  No identification with actual products is intended or should be inferred.  All examples involve the same CoAP problem type with semantics of "unknown key id", defined in the fictitious namespace `http://vocabulary.private-api.example`.

Note that CoRAL documents are exchanged in CoRAL binary format (Section 3 of {{!I-D.ietf-core-coral}}) in practice. This includes the use of {{?I-D.ietf-core-href}} as an alternative to URIs that is optimized for constrained nodes.

The example in {{fig-example-minimalist}} has the most compact representation.  It avoids any non-mandatory element.  This is suitable for a constrained receiver that happens to have precise knowledge of the semantics associated with the "type".

~~~
#using pd = <http://example.org/vocabulary/problem-details#>
#using ex = <http://vocabulary.private-api.example/#>

pd:type         ex:unknown-key-id
~~~
{: #fig-example-minimalist title="Minimalist"}

The example in {{fig-example-full-fledged}} has all the mandatory as well as the optional elements populated.  This format is appropriate for a less constrained receiver (for example, an edge gateway forwarding to a log server that needs to gather as much contextual information as possible, including the problem "headline", details about the error condition, and an error-specific instance URL).

~~~
#using pd = <http://example.org/vocabulary/problem-details#>
#using ex = <http://vocabulary.private-api.example/#>

pd:type         ex:unknown-key-id
pd:title        "unknown key id"
pd:detail       "Key with id 0x01020304 not registered"
pd:instance     <https://private-api.example/errors/5>
~~~
{: #fig-example-full-fledged title="Full-Fledged"}

# Additional Features

In the following sections we introduce specific (albeit "common enough") use
cases, and define the extensions to the basic format needed to support them.

## Tracing and Extended Diagnostic

Consumers of Problem Details might be located at the far end of a logging and
analytics pipeline.  For example, this might be the case when a CoAP server or
CoAP API gateway is located in an edge gateway node and forwards its logs to a
cloud collector, which in turn aggregates a potentially huge number of
different servers and transactions (see {{fig-log-pipeline}}).

~~~
{::include log-pipeline.ascii-art}
~~~
{: #fig-log-pipeline title="Logging Pipeline"}

It is quite common in a situation like the above that an already deployed
server is temporarily put in "tracing mode" to diagnose a failure.  In this
case having a separate channel for the tracing info provides a superior
solution (in terms of ease of ingesting and processing) to overloading the
`detail` field and having to write ad-hoc filtering logics to extract the
relevant information from it.  Cost-wise, the producer would not incur any
added overhead while, from the transport perspective, the slight increase in
bandwidth to support the extra structuring is typically dwarfed by the
(verbose) content of the diagnostic payload.  The same mechanism would also be
useful during the development and test of a new application, giving the
developer insight into the internal state of the application.

The additional protocol element is:

* "diag" (text) - a string.  It may contain anything of user's choice: extra
  information complementing the what already present in `detail`, a stack
  trace, a distributed trace span ending in an error condition, etc.

Leaking private or sensitive data SHOULD be avoided.

### Examples

The example in {{fig-example-diag-stack}} has a `diag` element with a stack
trace associated with the error condition.

~~~
#using pd = <http://example.org/vocabulary/problem-details#>
#using ex = <http://vocabulary.private-api.example/#>

pd:type         pd:server-error
pd:title        "internal server error"
pd:detail       "handler exception"
pd:instance     <https://private-api.example/errors/2>
pd:diag         "File \"example.py\", line 7, in \<module\>\n
                 caller()\nFile \"example.py\", line 5, in caller\n
                 callee()\nFile \"example.py\", line 2, in callee\n
                 raise Exception(\"Yikes\")\n"
~~~
{: #fig-example-diag-stack title="Diagnostic message containing a stack trace"}

# Additional Problem Details
{: #sec-new-attributes}

Problem type definitions MAY extend the Problem Details document with additional elements to convey additional, problem-specific information.

Clients consuming problem details MUST ignore any such elements that they do not recognize; this allows problem types to evolve and include additional information in the future.

## Examples

The example in {{fig-example-ext-full}} has all the basic elements as well as an additional, type-specific element.

~~~
#using pd = <http://example.org/vocabulary/problem-details#>
#using ex = <http://vocabulary.private-api.example/#>

pd:type         ex:unknown-key-id
pd:title        "unknown key id"
pd:detail       "Key with id 0x01020304 not registered"
pd:instance     <https://private-api.example/errors/5>
ex:key-id       0x01020304
~~~
{: #fig-example-ext-full title="Full Payload and Extensions"}

# Security Considerations

Problem Details for CoAP APIs are serialized in the CoRAL binary format.  See Section 11 of {{!RFC7252}}  for security considerations relating to CoAP.  See Section 7 of {{!I-D.ietf-core-coral}} for security considerations relating to
CoRAL.

The security and privacy considerations outlined in Section 5 of {{?RFC7807}} apply in full.

# IANA Considerations

TODO.

--- back

# Acknowledgments
{: numbered="no"}

Mark Nottingham and Erik Wilde, authors of RFC 7807.  Carsten Bormann, Jim Schaad, Christian Amsüss for review and comments on this document.
