---
type: entity
title: "Example Entity"
entity_type: person
role: "Illustrative example"
first_mentioned: "[[example-source]]"
created: "{{today}}"
updated: "{{today}}"
tags:
  - entity
  - example
status: seed
confidence: INFERRED
evidence:
  - "[[example-source]]"
related:
  - "[[example-concept]]"
  - "[[example-question]]"
---

# Example Entity

## Overview

An entity page records a named real-world thing: a person, tool, organization, product, or repository. Unlike concept pages, entities are proper nouns — they refer to something specific that exists or existed.

## Key Facts

- Entity type is set in frontmatter (`entity_type`)
- The `first_mentioned` field links to the source where this entity first appeared
- Use [[example-concept]] as context for how this entity relates to broader patterns

## Connections

- Mentioned in: [[example-source]]
- Related concept: [[example-concept]]

## Sources

- [[example-source]]
