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

# Generate script
cd `_scripts`

Generate all templates:
`./generate-template-pages.sh all`

Generate only menu:
`./generate-template-pages.sh count`

Generate a specified template: (TODO)
`./generate-template-pages.sh name xxxx`