# Obsidian Bases Examples

## Wiki Content Dashboard (all non-meta pages)

```yaml
filters:
  and:
    - file.inFolder("wiki/")
    - not:
        - file.inFolder("wiki/meta")

formulas:
  age: "(now() - file.ctime).days.round(0)"

properties:
  formula.age:
    displayName: "Age (days)"

views:
  - type: table
    name: "All Wiki Pages"
    order:
      - file.name
      - type
      - status
      - updated
      - formula.age
    groupBy:
      property: type
      direction: ASC
```

## Entity Index (people, orgs, repos)

```yaml
filters:
  and:
    - file.inFolder("wiki/entities/")
    - 'file.ext == "md"'

views:
  - type: table
    name: "Entities"
    order:
      - file.name
      - entity_type
      - status
      - updated
    groupBy:
      property: entity_type
      direction: ASC
```

## Recent Ingests (Sources)

```yaml
filters:
  and:
    - file.inFolder("wiki/sources/")

views:
  - type: table
    name: "Sources"
    order:
      - file.name
      - source_type
      - created
      - status
    groupBy:
      property: source_type
      direction: ASC
```

## View Type Examples

### Table View

```yaml
views:
  - type: table
    name: "Wiki Index"
    limit: 100
    order:
      - file.name
      - type
      - status
      - updated
    groupBy:
      property: type
      direction: ASC
```

### Cards View

```yaml
views:
  - type: cards
    name: "Gallery"
    order:
      - file.name
      - tags
      - status
```

### List View

```yaml
views:
  - type: list
    name: "Quick List"
    order:
      - file.name
      - status
```

## Complex Formula Examples

**Days since created (age):**
```yaml
age_days: "(now() - file.ctime).days.round(0)"
```

**Days until a date property:**
```yaml
days_until: 'if(due_date, (date(due_date) - today()).days, "")'
```

**Conditional status icon:**
```yaml
status_icon: 'if(status == "mature", "✅", if(status == "developing", "🔄", "🌱"))'
```

**Word count estimate:**
```yaml
word_est: "(file.size / 5).round(0)"
```

**Key rule:** Subtracting two dates returns a `Duration`, not a number. Always access `.days` first:
```yaml
# CORRECT
age: '(now() - file.ctime).days'

# WRONG (crashes)
age: '(now() - file.ctime).round(0)'
```

**Always guard nullable properties:**
```yaml
# CORRECT
days_left: 'if(due_date, (date(due_date) - today()).days, "")'
```
