# MagicTemplate

Template generate script pre-install:

Pug (template engine):
`npm install pug-cli -g`

Reference:
https://github.com/pugjs/pug


jq (shell json parser):
`brew install jq`

Reference:
https://stedolan.github.io/jq/

# Template generating script
cd `_scripts`

Tasks:

Generate all templates and left menu:
`./generate-template-pages.sh all`

Generate a specified template: 
`./generate-template-pages.sh name "{NAME}"`

- Fetch and generate template page of name match {NAME} on Airtable (case sensitive)

Example: 
`./generate-template-pages.sh name "8 isolate"`


Generate template in a view:
`./generate-template-pages.sh view Approved``



Disabled:
Generate only menu:
`./generate-template-pages.sh count`